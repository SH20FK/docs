# scratch/generate_icons.py
# Генерация чистых, четких PNG-иконок для мода strategist с антиалиасингом и прозрачностью.

from PIL import Image, ImageDraw
import os

OUT_DIR = r"C:\Users\Александр\AppData\Roaming\Pax Universe\mods\strategist\icons"
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 64  # Высокое разрешение для ретины/масштабирования в UI

def create_base():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# 1. Academic (Академик) - Атом и мантия
def make_academic():
    img = create_base()
    d = ImageDraw.Draw(img)
    # Золотистый атом / циркуль
    c_gold = (255, 213, 79, 255)
    c_blue = (129, 212, 250, 255)
    # Орбиты
    d.ellipse([10, 20, 54, 44], outline=c_blue, width=3)
    d.ellipse([20, 10, 44, 54], outline=c_blue, width=3)
    # Центральное ядро
    d.ellipse([26, 26, 38, 38], fill=c_gold, outline=(255, 245, 157, 255), width=2)
    return img

# 2. Commander (Полевой командир) - Скрещенные клинки
def make_commander():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_red = (255, 82, 82, 255)
    c_metal = (245, 245, 245, 255)
    # Клинки
    d.line([12, 12, 52, 52], fill=c_metal, width=5)
    d.line([52, 12, 12, 52], fill=c_metal, width=5)
    # Гарды
    d.line([14, 24, 24, 14], fill=c_red, width=4)
    d.line([50, 24, 40, 14], fill=c_red, width=4)
    # Центральный щиток
    d.ellipse([27, 27, 37, 37], fill=c_red, outline=c_metal, width=2)
    return img

# 3. Fox (Лис) - Маска/силуэт
def make_fox():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_orange = (255, 171, 64, 255)
    c_white = (255, 255, 255, 255)
    # Уши и морда
    points = [(12, 14), (24, 38), (32, 28), (40, 38), (52, 14), (44, 46), (32, 56), (20, 46)]
    d.polygon(points, fill=c_orange, outline=c_white)
    # Глаза
    d.ellipse([22, 34, 26, 38], fill=c_white)
    d.ellipse([38, 34, 42, 38], fill=c_white)
    # Нос
    d.ellipse([30, 48, 34, 52], fill=(40, 40, 40, 255))
    return img

# 4. Oracle (Оракул) - Кристалл и глаз
def make_oracle():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_purp = (179, 136, 255, 255)
    c_glow = (224, 64, 251, 255)
    # Ромб-кристалл
    d.polygon([(32, 8), (54, 32), (32, 56), (10, 32)], fill=(40, 20, 60, 200), outline=c_purp, width=3)
    # Внутренний кристалл
    d.polygon([(32, 18), (46, 32), (32, 46), (18, 32)], fill=c_glow)
    d.ellipse([28, 28, 36, 36], fill=(255, 255, 255, 255))
    return img

# 5. Fortress (Крепость)
def make_fortress():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_blue = (100, 181, 246, 255)
    c_gold = (255, 213, 79, 255)
    # Щит
    d.polygon([(32, 8), (54, 16), (54, 36), (32, 56), (10, 36), (10, 16)], fill=(15, 25, 45, 220), outline=c_blue, width=3)
    # Башня
    d.rectangle([24, 24, 40, 44], fill=c_gold)
    d.rectangle([22, 20, 26, 24], fill=c_gold)
    d.rectangle([30, 20, 34, 24], fill=c_gold)
    d.rectangle([38, 20, 42, 24], fill=c_gold)
    return img

# 6. Space (Космос)
def make_space():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_cyan = (64, 196, 255, 255)
    c_white = (255, 255, 255, 255)
    # Ракета
    d.polygon([(48, 10), (52, 24), (38, 38), (24, 52), (10, 52), (10, 38), (24, 24), (38, 10)], fill=(20, 40, 70, 220), outline=c_cyan, width=3)
    # Иллюминатор
    d.ellipse([34, 22, 42, 30], fill=c_white)
    # Пламя
    d.polygon([(10, 52), (18, 54), (8, 60), (14, 50)], fill=(255, 112, 67, 255))
    return img

# 7. Hegemony (Гегемония)
def make_hegemony():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    c_red = (255, 82, 82, 255)
    # Корона
    points = [(10, 44), (10, 22), (20, 32), (32, 14), (44, 32), (54, 22), (54, 44)]
    d.polygon(points, fill=c_gold, outline=c_red, width=3)
    d.ellipse([8, 18, 14, 24], fill=c_red)
    d.ellipse([30, 10, 36, 16], fill=c_red)
    d.ellipse([50, 18, 56, 24], fill=c_red)
    d.rectangle([10, 46, 54, 52], fill=c_gold)
    return img

# 8. Target (Цель / План)
def make_target():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    c_red = (255, 82, 82, 255)
    d.ellipse([10, 10, 54, 54], outline=c_gold, width=3)
    d.ellipse([20, 20, 44, 44], outline=c_gold, width=2)
    d.ellipse([28, 28, 36, 36], fill=c_red)
    d.line([32, 6, 32, 18], fill=c_gold, width=3)
    d.line([32, 46, 32, 58], fill=c_gold, width=3)
    d.line([6, 32, 18, 32], fill=c_gold, width=3)
    d.line([46, 32, 58, 32], fill=c_gold, width=3)
    return img

# 9. Threat (Угроза)
def make_threat():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_red = (255, 82, 82, 255)
    c_white = (255, 255, 255, 255)
    d.polygon([(32, 8), (56, 52), (8, 52)], fill=(60, 15, 15, 220), outline=c_red, width=4)
    d.line([32, 22, 32, 36], fill=c_white, width=4)
    d.ellipse([30, 42, 34, 46], fill=c_white)
    return img

# 10. Opportunity (Возможность)
def make_opportunity():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_cyan = (64, 196, 255, 255)
    d.ellipse([10, 10, 54, 54], outline=c_cyan, width=3)
    # Стрелка вверх-вправо
    d.line([22, 42, 42, 22], fill=c_cyan, width=4)
    d.line([42, 22, 30, 22], fill=c_cyan, width=4)
    d.line([42, 22, 42, 34], fill=c_cyan, width=4)
    return img

# 11. Order (Приказ / Молния)
def make_order():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    points = [(36, 6), (16, 32), (32, 32), (26, 58), (50, 26), (34, 26)]
    d.polygon(points, fill=c_gold, outline=(255, 245, 157, 255), width=2)
    return img

# 12. Check (Выполнено)
def make_check():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_green = (105, 240, 174, 255)
    d.ellipse([8, 8, 56, 56], fill=(15, 45, 25, 220), outline=c_green, width=3)
    d.line([20, 32, 28, 42], fill=c_green, width=5)
    d.line([28, 42, 44, 20], fill=c_green, width=5)
    return img

# 13. Cross (Провалено)
def make_cross():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_red = (255, 82, 82, 255)
    d.ellipse([8, 8, 56, 56], fill=(45, 15, 15, 220), outline=c_red, width=3)
    d.line([22, 22, 42, 42], fill=c_red, width=5)
    d.line([42, 22, 22, 42], fill=c_red, width=5)
    return img

# 14. Hourglass (Ожидание)
def make_hourglass():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_blue = (144, 202, 249, 255)
    d.line([14, 12, 50, 12], fill=c_blue, width=4)
    d.line([14, 52, 50, 52], fill=c_blue, width=4)
    d.polygon([(18, 14), (46, 14), (32, 32)], fill=(20, 35, 60, 200), outline=c_blue, width=2)
    d.polygon([(32, 32), (46, 50), (18, 50)], fill=(20, 35, 60, 200), outline=c_blue, width=2)
    d.ellipse([30, 42, 34, 46], fill=(255, 213, 79, 255))
    return img

# 15. Scroll (Летопись)
def make_scroll():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    c_paper = (236, 239, 241, 255)
    d.rectangle([16, 12, 48, 52], fill=(25, 35, 50, 220), outline=c_gold, width=3)
    d.line([22, 22, 42, 22], fill=c_paper, width=3)
    d.line([22, 30, 42, 30], fill=c_paper, width=3)
    d.line([22, 38, 34, 38], fill=c_paper, width=3)
    return img

# 16. Insight (Совет)
def make_insight():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    c_glow = (255, 245, 157, 255)
    d.ellipse([18, 10, 46, 38], fill=c_gold, outline=c_glow, width=2)
    d.rectangle([24, 36, 40, 46], fill=(120, 144, 156, 255))
    d.rectangle([28, 46, 36, 50], fill=(84, 110, 122, 255))
    return img

# 17. Capitol (Держава)
def make_capitol():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    c_blue = (144, 202, 249, 255)
    d.polygon([(32, 10), (54, 24), (10, 24)], fill=(30, 40, 60, 220), outline=c_gold, width=3)
    d.line([14, 26, 14, 48], fill=c_blue, width=4)
    d.line([26, 26, 26, 48], fill=c_blue, width=4)
    d.line([38, 26, 38, 48], fill=c_blue, width=4)
    d.line([50, 26, 50, 48], fill=c_blue, width=4)
    d.rectangle([8, 48, 56, 54], fill=c_gold)
    return img

# 18. Refresh (Пересборка)
def make_refresh():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_cyan = (64, 196, 255, 255)
    d.arc([12, 12, 52, 52], start=30, end=300, fill=c_cyan, width=4)
    d.polygon([(48, 14), (56, 24), (42, 26)], fill=c_cyan)
    return img

# 19. Star (Звезда)
def make_star():
    img = create_base()
    d = ImageDraw.Draw(img)
    c_gold = (255, 213, 79, 255)
    # Звезда
    points = [
        (32, 8), (38, 24), (56, 26), (42, 38), (46, 54),
        (32, 44), (18, 54), (22, 38), (8, 26), (26, 24)
    ]
    d.polygon(points, fill=c_gold, outline=(255, 245, 157, 255), width=2)
    return img

# Генерация всех иконок
ICONS = {
    "icon_academic.png": make_academic,
    "icon_commander.png": make_commander,
    "icon_fox.png": make_fox,
    "icon_oracle.png": make_oracle,
    "icon_fortress.png": make_fortress,
    "icon_space.png": make_space,
    "icon_hegemony.png": make_hegemony,
    "icon_target.png": make_target,
    "icon_threat.png": make_threat,
    "icon_opportunity.png": make_opportunity,
    "icon_order.png": make_order,
    "icon_check.png": make_check,
    "icon_cross.png": make_cross,
    "icon_hourglass.png": make_hourglass,
    "icon_scroll.png": make_scroll,
    "icon_insight.png": make_insight,
    "icon_capitol.png": make_capitol,
    "icon_refresh.png": make_refresh,
    "icon_star.png": make_star
}

for filename, func in ICONS.items():
    out_path = os.path.join(OUT_DIR, filename)
    img = func()
    img.save(out_path, "PNG")
    print(f"Generated {filename}")

print("All PNG icons generated successfully!")
