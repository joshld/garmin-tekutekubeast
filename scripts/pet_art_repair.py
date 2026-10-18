"""Narrow atlas-bleed repair, without cropping/scaling/repositioning artwork."""
from collections import deque


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
