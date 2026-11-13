#!/usr/bin/env python3
"""Seed (or remove) a demo catalogue in one shop on the remote project.

Rows are written the way the app's product form writes them
(lib/modules/shop/controllers/product_form_controller.dart): same columns,
same `data` keys, one photo in the `product-images` bucket under
`<userId>/<millis>_<name>.jpg` used as both image_url and raw_image_url.
Every seeded row carries `data.seed = SEED_TAG`, and `data.seedImagePath`
names its storage object, so the seed can be found and removed again.

Photos are free-licence Unsplash images (https://unsplash.com/license).

Usage (service role key from env, else read through the linked Supabase CLI):
  python3 -I supabase/scripts/seed_demo_shop.py seed   <email> <scratch_dir>
  python3 -I supabase/scripts/seed_demo_shop.py remove <email>

`seed` removes any earlier seed for that shop first, so it is re-runnable.
"""

import json
import os
import random
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

PROJECT_REF = "dararqifsiuvrmfjleui"
BASE_URL = f"https://{PROJECT_REF}.supabase.co"
BUCKET = "product-images"
SEED_TAG = "demo-catalogue-v1"
PHOTO_URL = "https://images.unsplash.com/{id}?w=1080&q=80&fm=jpg&fit=max"

APPAREL_SIZES = ["XS", "S", "M", "L", "XL"]
SHOE_SIZES = ["UK 4", "UK 5", "UK 6", "UK 7", "UK 8", "UK 9", "UK 10"]

# (photo id, name, category, subcategory, gender, style, colours, weather,
#  functional, (min $, max $), linen type, made where, description, details)
CATALOGUE = [
    ("photo-1581655353564-df123a1eb820", "Essential Cotton Crew Tee", "tops",
     "t-shirts", "unisex", "casual", ["white"], ["hot", "mild"],
     ["breathable"], (8, 18), "100% combed cotton", "Zimbabwe",
     "A heavyweight everyday crew neck with a soft hand feel and a relaxed, "
     "straight fit. Holds its shape wash after wash.",
     ["Pre-shrunk", "Ribbed collar"]),
    ("photo-1740711152088-88a009e877bb", "Harare Linen Button-Down",
     "tops", "shirts", "male", "corporate", ["blue"], ["hot", "mild"],
     ["breathable"], (28, 48), "Pure linen", "South Africa",
     "Washed linen shirt in sky blue with a classic collar and mother-of-pearl "
     "style buttons. Cool enough for summer office days.",
     ["Chest pocket", "Curved hem"]),
    ("photo-1556821840-3a63f95609a7", "Everyday Pullover Hoodie", "tops",
     "hoodies", "unisex", "streetwear", ["grey"], ["cool", "cold"],
     ["insulated"], (25, 45), "Cotton-poly fleece", "Zimbabwe",
     "Brushed-back fleece hoodie in heather grey with a lined hood and "
     "kangaroo pocket. Made for chilly evenings.",
     ["Lined hood", "Ribbed cuffs"]),
    ("photo-1620799140408-edc6dcb6d633", "Cloud Long-Sleeve Crew", "tops",
     "sweatshirts", "female", "casual", ["white"], ["mild", "cool"], [],
     (22, 38), "Organic cotton jersey", "Kenya",
     "Clean white long-sleeve crew in a midweight jersey. Layers under "
     "blazers or wears on its own with denim.",
     ["Dropped shoulder"]),
    ("photo-1605154733982-8e32960646e7", "Sunshine Stripe Tank", "tops",
     "tank tops", "female", "casual", ["yellow", "white"], ["hot"],
     ["breathable"], (10, 20), "Cotton rib", "Zimbabwe",
     "Fitted ribbed tank in a cheerful yellow and white stripe. Easy to pair "
     "with shorts, skirts and wide-leg trousers.",
     []),
    ("photo-1671438118097-479e63198629", "Classic Piqué Polo", "tops",
     "polo shirts", "male", "corporate", ["white"], ["hot", "mild"],
     ["breathable"], (18, 32), "Cotton piqué", "South Africa",
     "A crisp white piqué polo with a two-button placket. Smart enough for "
     "the office, relaxed enough for the weekend.",
     ["Side vents"]),
    ("photo-1714143136372-ddaf8b606da7", "Mid-Blue Straight Jeans",
     "bottoms", "jeans", "unisex", "casual", ["blue"], ["mild", "cool"], [],
     (35, 60), "12oz cotton denim", "Mauritius",
     "Straight-leg jeans in a mid-blue wash with a regular rise. Sturdy "
     "denim that softens with wear.",
     ["Five pockets", "Zip fly"]),
    ("photo-1591195853828-11db59a44f6b", "Frayed Denim Shorts", "bottoms",
     "shorts", "female", "casual", ["blue"], ["hot"], ["breathable"],
     (15, 28), "Cotton denim", "Zimbabwe",
     "High-rise denim shorts with a frayed hem. A summer staple for markets "
     "and road trips.",
     []),
    ("photo-1789110853398-539d78dd63bc", "Midnight Pleated Skirt",
     "bottoms", "skirts", "female", "glamour", ["black"], ["mild"], [],
     (25, 45), "Satin-finish polyester", "South Africa",
     "Knife-pleated midi skirt with an elastic back waist. Moves "
     "beautifully and dresses up a plain tee.",
     ["Elastic back waist"]),
    ("photo-1789111161057-90c5ce12dc21", "Sculpt High-Waist Leggings",
     "bottoms", "leggings", "female", "streetwear", ["black"],
     ["mild", "cool"], ["breathable"], (15, 30), "Nylon-spandex", "Kenya",
     "Squat-proof high-waist leggings with four-way stretch. From the gym "
     "to errands without a second thought.",
     ["Hidden waist pocket"]),
    ("photo-1552902875-9ac1f9fe0c07", "Tapered Cotton Joggers",
     "bottoms", "joggers", "unisex", "streetwear", ["black"],
     ["cool", "cold"], ["insulated"], (20, 38), "Brushed cotton fleece",
     "Zimbabwe",
     "Tapered joggers with a drawstring waist and cuffed ankles. Soft "
     "inside, neat enough to wear out.",
     ["Drawstring waist", "Side pockets"]),
    ("photo-1762154057377-cc9d3dd6900c", "Garden Party Floral Sundress",
     "dresses", "", "female", "afrochic", ["pink", "green"], ["hot"],
     ["breathable"], (35, 65), "Viscose", "Zimbabwe",
     "Flowing floral sundress with a fitted bodice and a twirl-ready skirt. "
     "Made for weddings, brunches and long summer days.",
     ["Adjustable straps", "Lined bodice"]),
    ("photo-1623580674393-edf6eb7090f8", "Evening Little Black Dress",
     "dresses", "", "female", "glamour", ["black"], ["mild"], [], (45, 85),
     "Crepe", "South Africa",
     "A sleeveless black dress cut close to the body with a clean neckline. "
     "The one you reach for every evening out.",
     ["Invisible back zip"]),
    ("photo-1609357605129-26f69add5d6e", "Emerald Long-Sleeve Maxi",
     "dresses", "", "female", "afrochic", ["green"], ["mild", "cool"], [],
     (50, 95), "Chiffon", "Zimbabwe",
     "Floor-length emerald maxi with long sheer sleeves and a soft tie "
     "waist. Statement colour for special occasions.",
     ["Tie waist", "Fully lined"]),
    ("photo-1611312449408-fcece27cdbb7", "Vintage Wash Denim Jacket",
     "outerwear", "jackets", "unisex", "streetwear", ["blue"],
     ["mild", "cool"], ["windproof"], (40, 70), "Rigid cotton denim",
     "Mauritius",
     "Classic trucker jacket in a vintage blue wash. Throw it over "
     "everything from dresses to hoodies.",
     ["Button chest pockets"]),
    ("photo-1551028719-00167b16eac5", "Moto Leather Jacket", "outerwear",
     "jackets", "unisex", "streetwear", ["black"], ["cool", "cold"],
     ["windproof", "insulated"], (85, 120), "Genuine lambskin leather",
     "South Africa",
     "Black biker jacket in soft genuine leather with an asymmetric zip and "
     "quilted lining.",
     ["Quilted lining", "Zip cuffs"]),
    ("photo-1779400202021-3c23b8590b66", "Tailored Black Blazer",
     "outerwear", "blazers", "female", "corporate", ["black"],
     ["mild", "cool"], [], (55, 95), "Wool blend", "South Africa",
     "Sharp single-breasted blazer with structured shoulders and a slim "
     "waist. Boardroom ready, great with jeans too.",
     ["Flap pockets", "Fully lined"]),
    ("photo-1633821879282-0c4e91f96232", "Camel Belted Trench Coat",
     "outerwear", "", "female", "corporate", ["beige"], ["cool", "rainy"],
     ["waterproof", "windproof"], (75, 120), "Water-resistant cotton gabardine",
     "Kenya",
     "Double-breasted trench in camel with a removable belt and storm flap. "
     "Keeps the rain off in style.",
     ["Removable belt", "Storm flap"]),
    ("photo-1600269452121-4f2416e55c28", "Court Low-Top Sneakers", "shoes",
     "sneakers", "unisex", "streetwear", ["white"], ["mild", "hot"], [],
     (45, 85), "Leather upper, rubber sole", "Kenya",
     "Clean white low-tops with a cushioned insole and a grippy cupsole. "
     "Goes with absolutely everything.",
     ["Cushioned insole"]),
    ("photo-1608256246200-53e635b5b65f", "Rugged Lace-Up Leather Boots",
     "shoes", "boots", "male", "casual", ["brown"], ["cool", "cold", "rainy"],
     ["waterproof"], (70, 120), "Full-grain leather", "Zimbabwe",
     "Hand-finished brown leather work boots with a lug sole. Built to last "
     "seasons of wear.",
     ["Goodyear welt", "Padded collar"]),
    ("photo-1535043934128-cf0b28d52f95", "Pearl Textured Pumps", "shoes",
     "heels", "female", "glamour", ["white"], ["mild"], [], (40, 75),
     "Textured faux leather", "South Africa",
     "Pointed white pumps on a 9cm heel with a subtle textured finish. "
     "Bridal, evening and everything in between.",
     ["9cm heel", "Padded footbed"]),
    ("photo-1603487742131-4160ec999306", "Two-Tone Slide Sandals", "shoes",
     "sandals", "unisex", "casual", ["brown", "grey"], ["hot"],
     ["breathable"], (12, 28), "Moulded EVA", "Zimbabwe",
     "Lightweight slides with a contoured footbed. Poolside, beach or just "
     "around the house.",
     []),
    ("photo-1674500762924-612a431c28dd", "Gilded Ballet Flats", "shoes",
     "flats", "female", "glamour", ["yellow"], ["hot", "mild"], [],
     (30, 55), "Metallic faux leather", "South Africa",
     "Soft gold ballet flats with a cushioned sole. A little shine for "
     "everyday outfits.",
     ["Flexible sole"]),
    ("photo-1577803645773-f96470509666", "Ivory Frame Sunglasses",
     "accessories", "glasses", "unisex", "glamour", ["white", "brown"],
     ["hot"], [], (15, 35), "Acetate frame, UV400 lenses", "China",
     "Retro ivory frames with warm brown lenses and full UV400 protection.",
     ["UV400", "Comes with case"]),
    ("photo-1588850561407-ed78c282e89b", "Washed Cotton Dad Cap",
     "accessories", "caps", "unisex", "streetwear", ["white"], ["hot"],
     ["breathable"], (8, 18), "Washed cotton twill", "Zimbabwe",
     "Unstructured six-panel cap with an adjustable strap back.",
     ["Adjustable strap"]),
    ("photo-1583238619747-27950824e04d", "Woven Wide-Brim Sun Hat",
     "accessories", "hats", "female", "afrochic", ["brown"], ["hot"],
     ["breathable"], (18, 35), "Natural straw", "Zimbabwe",
     "Handwoven wide-brim hat with a grosgrain band. Shade for long days "
     "outdoors.",
     ["Handwoven"]),
    ("photo-1524805444758-089113d48a6d", "Heritage Chronograph Watch",
     "accessories", "", "male", "corporate", ["brown", "grey"], [], [],
     (60, 120), "Stainless steel case, leather strap", "Japan",
     "Silver chronograph with a cream dial on a tan leather strap. Water "
     "resistant to 50m.",
     ["Quartz movement", "50m water resistant"]),
    ("photo-1605733513597-a8f8341084e6", "Slate Leather Satchel", "other",
     "", "female", "corporate", ["grey"], [], [], (65, 115),
     "Genuine leather", "Zimbabwe",
     "Structured leather satchel with gold-tone buckles and an adjustable "
     "shoulder strap. Fits a 13-inch laptop.",
     ["Adjustable strap", "Inner zip pocket"]),
    ("photo-1544816155-12df9643f363", "Everyday Canvas Tote", "other", "",
     "unisex", "casual", ["beige"], [], [], (8, 18), "Heavy cotton canvas",
     "Zimbabwe",
     "Roomy natural canvas tote for markets, books and beach days.",
     ["Reinforced handles"]),
    ("photo-1711443982852-b3df5c563448", "Hand-Stitched Leather Belt",
     "other", "", "male", "corporate", ["brown"], [], [], (15, 35),
     "Full-grain leather", "Zimbabwe",
     "Brown full-grain belt with a brushed metal buckle. Ages into a rich "
     "patina.",
     ["Brushed buckle"]),
]


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def service_key():
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if key:
        return key
    out = subprocess.run(
        ["supabase", "projects", "api-keys", "--project-ref", PROJECT_REF,
         "-o", "json"],
        capture_output=True, text=True, check=False,
    )
    if out.returncode != 0:
        fail("set SUPABASE_SERVICE_ROLE_KEY or link the Supabase CLI")
    for entry in json.loads(out.stdout):
        if entry.get("name") == "service_role":
            return entry["api_key"]
    fail("no service_role key returned by the Supabase CLI")


class RequestFailed(Exception):
    pass


def request(key, method, path, body=None, headers=None, raw=False):
    data = body if raw or body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE_URL + path, data=data, method=method)
    req.add_header("apikey", key)
    req.add_header("Authorization", f"Bearer {key}")
    if not raw:
        req.add_header("Content-Type", "application/json")
    for name, value in (headers or {}).items():
        req.add_header(name, value)
    try:
        with urllib.request.urlopen(req, timeout=60) as res:
            text = res.read().decode() or "null"
            return json.loads(text)
    except urllib.error.HTTPError as error:
        raise RequestFailed(
            f"{method} {path} -> {error.code}: {error.read().decode()[:300]}"
        ) from error


def find_shop(key, email):
    query = urllib.parse.urlencode({"email": f"eq.{email}", "select": "id"})
    rows = request(key, "GET", f"/rest/v1/private_account?{query}")
    if not rows:
        fail(f"no account with email {email}")
    user_id = rows[0]["id"]
    rows = request(key, "GET",
                   f"/rest/v1/profiles?id=eq.{user_id}&select=shop,display_name")
    shop = (rows[0] if rows else {}).get("shop") or {}
    if not shop.get("name"):
        fail(f"{email} has no shop set up")
    return user_id, shop["name"]


def remove_seed(key, user_id):
    query = urllib.parse.urlencode({
        "user_id": f"eq.{user_id}",
        "data->>seed": f"eq.{SEED_TAG}",
        "select": "id,data",
    })
    rows = request(key, "GET", f"/rest/v1/products?{query}")
    if rows:
        ids = ",".join(r["id"] for r in rows)
        request(key, "DELETE", f"/rest/v1/products?id=in.({ids})")
    # Images go by what is in storage, not only by what rows point at, so
    # files left behind by an earlier interrupted run are cleaned up too.
    paths = sorted({r["data"].get("seedImagePath") for r in rows} - {None}
                   | set(stray_seed_images(key, user_id)))
    deleted = delete_images(key, paths)
    left = stray_seed_images(key, user_id)
    print(f"removed {len(rows)} seeded products and {deleted} images"
          + (f"; {len(left)} images could not be deleted" if left else ""))


def stray_seed_images(key, user_id):
    """Seed-named images in the shop's folder (`<millis>_<seed name>.jpg`)."""
    names = {safe_name(item[1]) for item in CATALOGUE}
    listed = request(key, "POST", f"/storage/v1/object/list/{BUCKET}",
                     {"prefix": f"{user_id}/", "limit": 1000})
    paths = []
    for entry in listed or []:
        match = re.fullmatch(r"\d{13}_(.+)\.jpg", entry.get("name", ""))
        if match and match.group(1) in names:
            paths.append(f"{user_id}/{entry['name']}")
    return paths


def delete_images(key, paths, batch=10):
    """Deletes in small batches; returns how many storage confirmed."""
    deleted = 0
    for start in range(0, len(paths), batch):
        result = request(key, "DELETE", f"/storage/v1/object/{BUCKET}",
                         {"prefixes": paths[start:start + batch]})
        deleted += len(result or [])
    return deleted


def safe_name(value):
    name = re.sub(r"[^a-z0-9_-]+", "_", value.strip().lower())
    return re.sub(r"_+", "_", name).strip("_") or "product"


def download(photo_id, scratch_dir):
    target = os.path.join(scratch_dir, f"{photo_id}.jpg")
    if not os.path.exists(target):
        req = urllib.request.Request(PHOTO_URL.format(id=photo_id),
                                     headers={"User-Agent": "banigoba-seed"})
        with urllib.request.urlopen(req, timeout=60) as res:
            if not res.headers.get("Content-Type", "").startswith("image/"):
                fail(f"{photo_id} did not return an image")
            with open(target, "wb") as handle:
                handle.write(res.read())
    with open(target, "rb") as handle:
        return handle.read()


def size_inventory(category, rng):
    if category in ("tops", "bottoms", "dresses", "outerwear"):
        sizes = APPAREL_SIZES
    elif category == "shoes":
        sizes = SHOE_SIZES
    else:
        return {}
    return {size: rng.randint(1, 8) for size in sizes}


def price_for(band, rng):
    low, high = band
    return round(rng.randint(low, high) - rng.choice([0.01, 0.01, 0.0, 0.51]), 2)


def build_row(item, user_id, shop_name, image_url, path, rng):
    (photo_id, name, category, subcategory, gender, style, colours, weather,
     functional, band, linen, made, description, details) = item
    inventory = size_inventory(category, rng)
    stock = sum(inventory.values()) if inventory else rng.randint(5, 25)
    row = {
        "user_id": user_id,
        "name": name,
        "description": description,
        "category": category,
        "subcategory": subcategory,
        "price": price_for(band, rng),
        "stock": stock,
        # Bulk inserts need identical keys; {} is the column default.
        "size_inventory": inventory,
        "image_url": image_url,
        "raw_image_url": image_url,
        "style_tag": style,
        "colours": colours,
        "gender": gender,
        "weather_tags": weather,
        "functional_tags": functional,
        "data": {
            "shoulderMeasurement": "",
            "heightMeasurement": "",
            "linenType": linen,
            "madeWhere": made,
            "otherDetails": details,
            "shopName": shop_name,
            "seed": SEED_TAG,
            "seedImagePath": path,
            "photoSource": f"https://unsplash.com ({photo_id})",
        },
    }
    return row


def seed(key, email, scratch_dir):
    if not os.path.isdir(scratch_dir):
        fail(f"scratch dir {scratch_dir} does not exist")
    user_id, shop_name = find_shop(key, email)
    remove_seed(key, user_id)
    rng = random.Random(SEED_TAG)
    rows = []
    try:
        for item in CATALOGUE:
            bytes_ = download(item[0], scratch_dir)
            millis = int(time.time() * 1000)
            path = f"{user_id}/{millis}_{safe_name(item[1])}.jpg"
            request(key, "POST", f"/storage/v1/object/{BUCKET}/{path}", bytes_,
                    {"Content-Type": "image/jpeg"}, raw=True)
            url = f"{BASE_URL}/storage/v1/object/public/{BUCKET}/{path}"
            rows.append(build_row(item, user_id, shop_name, url, path, rng))
            print(f"uploaded {item[1]}")
        request(key, "POST", "/rest/v1/products", rows,
                {"Prefer": "return=minimal"})
    except (RequestFailed, urllib.error.URLError) as error:
        # Don't leave images behind that no product points at.
        paths = [r["data"]["seedImagePath"] for r in rows]
        deleted = delete_images(key, paths)
        fail(f"{error} (rolled back {deleted} of {len(paths)} uploads)")
    prices = [r["price"] for r in rows]
    print(f"seeded {len(rows)} products into '{shop_name}' "
          f"(${min(prices):.2f} - ${max(prices):.2f})")


def main(argv):
    if len(argv) < 3 or argv[1] not in ("seed", "remove"):
        fail(__doc__)
    key = service_key()
    try:
        if argv[1] == "seed":
            if len(argv) != 4:
                fail("seed needs <email> <scratch_dir>")
            seed(key, argv[2], argv[3])
        else:
            user_id, _ = find_shop(key, argv[2])
            remove_seed(key, user_id)
    except RequestFailed as error:
        fail(str(error))


if __name__ == "__main__":
    main(sys.argv)
