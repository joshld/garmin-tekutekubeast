"""Narrow atlas-bleed repair, without cropping/scaling/repositioning artwork."""
from collections import deque


# Reviewed against the original expressive atlases. These boxes contain only
# neighbouring poses/rows, in historical 96px coordinates. Do not apply a
# generic component filter: food crumbs, flame sparks and tail details can be
# disconnected intentionally. Pet/Glance artwork is outside this game repair.
GAME_BLEED = {
    'Nimble': {1: [(0, 0, 12, 96)], 2: [(0, 0, 12, 96)],
               3: [(0, 0, 6, 96)], 4: [(0, 0, 8, 96)], 5: [(0, 0, 12, 96)]},
    'Grove4': {0: [(0, 88, 96, 96)], 1: [(0, 88, 96, 96)],
               2: [(0, 88, 96, 96)], 4: [(0, 88, 96, 96)], 5: [(0, 88, 96, 96)]},
    'Grove5': {1: [(0, 0, 12, 96)], 2: [(0, 0, 16, 96)],
               3: [(0, 0, 14, 96)], 4: [(0, 0, 8, 96)], 5: [(0, 0, 18, 96)]},
    'Ember4': {4: [(0, 94, 96, 96)]},
    'Ember5': {2: [(0, 0, 7, 96)], 3: [(88, 0, 96, 96)], 4: [(88, 0, 96, 96)]},
    'Tide3': {1: [(0, 0, 8, 96)], 2: [(0, 0, 18, 96)]},
    'Tide4': {0: [(0, 0, 96, 20)], 1: [(0, 0, 96, 20), (0, 20, 12, 96)],
              2: [(0, 0, 96, 20), (0, 20, 12, 96)], 3: [(0, 0, 96, 20)],
              4: [(0, 0, 96, 20)], 5: [(0, 0, 96, 20), (0, 20, 12, 96)]},
    'Tide5': {1: [(0, 0, 10, 96)], 2: [(0, 0, 16, 96)],
              3: [(0, 40, 9, 48)], 5: [(0, 0, 11, 96)]},
    'Wisp3': {2: [(0, 0, 6, 96)], 3: [(0, 0, 8, 96)], 4: [(0, 0, 7, 96)]},
    'Wisp4': {1: [(0, 0, 10, 96)], 2: [(0, 0, 18, 96)],
              3: [(0, 0, 14, 96)], 4: [(0, 0, 6, 96)], 5: [(0, 0, 11, 96)]},
    'Wisp5': {1: [(0, 0, 12, 96)], 2: [(0, 0, 22, 96)],
              4: [(0, 0, 12, 96)], 5: [(0, 0, 15, 96)]},
}


def repair_game(canvas, species, pose):
    """Erase only reviewed atlas bleed; never recrop/resize/reposition the body."""
    assert canvas.size == (96, 96)
    result = canvas.copy()
    for box in GAME_BLEED.get(species, {}).get(pose, []):
        result.paste((0, 0, 0, 0), box)
    return result


def repair_nimble(canvas):
    """Keep Nimble's connected body; fixed atlas cells captured adjacent tails.

    Only call for Nimble Pet poses, not arbitrary artwork: disconnected effects
    and hooves can be legitimate on other creatures. Preserve the body RGBA,
    original native canvas and transparent padding exactly.
    """
    result = canvas.copy()
    pixels = result.load()
    seen = set()
    components = []
    for y in range(result.height):
        for x in range(result.width):
            if (x, y) in seen or not pixels[x, y][3]:
                continue
            queue = deque([(x, y)])
            seen.add((x, y))
            component = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for nx, ny in ((px-1, py), (px+1, py), (px, py-1), (px, py+1)):
                    if (0 <= nx < result.width and 0 <= ny < result.height
                            and (nx, ny) not in seen and pixels[nx, ny][3]):
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)
    body = max(components, key=len)
    for component in components:
        if component is not body:
            for x, y in component:
                pixels[x, y] = (0, 0, 0, 0)
    return result
