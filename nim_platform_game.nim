import sdl2
import sdl2.image
import basic2d

type
  Input {.pure.} = enum none, left, right, jump, restart, quit

  Player = ref object
    texture: TexturePtr
    pos: Point2d
    vel: Vector2d

  Game = ref object
    inputs: array[Input, bool]
    renderer: RendererPtr
    player: Player
    camera: Vector2d

proc restartPlayer(player: Player) =
  player.pos = point2d(170,500)
  player.vel = vector2d(0, 0)

proc newPlayer(texture: TexturePtr): Player =
  new result
  result.texture = texture
  result.restartPlayer()

proc newGame(renderer: RendererPtr): Game =
  # TODO:
  new result
  result.renderer = renderer
  result.player = newPlayer(renderer.loadTexture("player.png"))

proc renderTee(renderer: RendererPtr, texture: TexturePtr, pos: Point2d) =
  let
    x = pos.x.cint
    y = pos.y.cint

  var bodyParts: array[8, tuple[source, dest: Rect, flip: cint]] = [
    (rect(192,  64, 64, 32), rect(x-60,    y, 96, 48), SDL_FLIP_NONE),      # back feet shadow
    (rect( 96,   0, 96, 96), rect(x-48, y-48, 96, 96), SDL_FLIP_NONE),      # body shadow
    (rect(192,  64, 64, 32), rect(x-36,    y, 96, 48), SDL_FLIP_NONE),      # front feet shadow
    (rect(192,  32, 64, 32), rect(x-60,    y, 96, 48), SDL_FLIP_NONE),      # back feet
    (rect(  0,   0, 96, 96), rect(x-48, y-48, 96, 96), SDL_FLIP_NONE),      # body
    (rect(192,  32, 64, 32), rect(x-36,    y, 96, 48), SDL_FLIP_NONE),      # front feet
    (rect( 64,  96, 32, 32), rect(x-18, y-21, 36, 36), SDL_FLIP_NONE),      # left eye
    (rect( 64,  96, 32, 32), rect( x-6, y-21, 36, 36), SDL_FLIP_HORIZONTAL) # right eye
  ]

  for part in bodyParts.mitems:
    renderer.copyEx(texture, part.source, part.dest, angle = 0.0, center = nil, flip = part.flip)


proc toInput(key: Scancode): Input =
  case key
  of SDL_SCANCODE_A: Input.left
  of SDL_SCANCODE_D: Input.right
  of SDL_SCANCODE_SPACE: Input.jump
  of SDL_SCANCODE_R: Input.restart
  of SDL_SCANCODE_Q: Input.quit
  else: Input.none

proc handleInput(game: Game) =
  # TODO:
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent: game.inputs[Input.quit] = true
    of KeyDown: game.inputs[event.key.keysym.scancode.toInput] = true
    of KeyUp: game.inputs[event.key.keysym.scancode.toInput] = false
    else: discard

# proc render(game: Game) =
#   # TODO:
#   game.renderer.clear()
#   game.renderer.present()


type SDLException = object of Exception

template sdlFailIf(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $getError())

proc main =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed"
  defer: sdl2.quit()

  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY", "2")):
    "Linear texture filtering could not be enabled"
  let window = createWindow(title = "Our own 2D platformer",
    x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
    w = 1280, h = 720, flags = SDL_WINDOW_SHOWN)
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer(index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync)
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()
  renderer.setDrawColor(r = 110, g = 132, b = 174)

  const imgFlags: cint = IMG_INIT_PNG
  sdlFailIf(image.init(imgFlags) != imgFlags):
    "SDL2 Image initialization failed"
  defer: image.quit()

  var game = newGame(renderer)

  while not game.inputs[Input.quit]:
    game.handleInput()
    game.renderer.renderTee(game.player.texture, game.player.pos - game.camera)
    game.renderer.present()

main()