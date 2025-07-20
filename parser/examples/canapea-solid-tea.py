application

import capability "canapea/experiments/ui"
  exposing
    | +SubscribeToSystemEvents
    | +SubscribeToUserEvents
    | +UpdateView
import capability "canapea/io"
  exposing
    | +StdOut

import "canapea/codec" as codec
  exposing
    | OpaqueValue
import "canapea/codec/json" as json
import "canapea/format" as fmt

import "experimental/tea" as tea
  exposing
    | Cmd
    | Next
    | Sub
    | ViewNode
import "experimental/tea/subscriptions" as subs

application config { main = browserMain }


type AppCapability =
  | Out is [ +StdOut ]
  | SystemEvents is [ +SubscribeToSystemEvents "param" ]
  | ViewAccess is [ +SubscribeToUserEvents, +UpdateView ]


let browserMain : OpaqueValue -> <Out,SystemEvents,ViewAccess>Eventual _ _
let browserMain flags =
  let { initialCount } =
    when codec.decode json.codec flags is
      | InvalidJson msg -> { initialCount = 0 }
      | else decoded -> decoded

  tea.program
    (tea.model { count = initialCount })
    (tea.view ViewAccess
      { model ->
        let nodes = view model
        tea.mapMsg nodes { ViewMsg it }
      }
    )
    update
    (tea.subscriptions SystemEvents subscribe)

type Msg =
  | Resized { width : Decimal, height : Decimal }
  | ViewMsg ViewMsg

type ViewMsg =
  | Inc

# TODO: Support `type new`? How would we create its values? Is it "infectious"?
type new Count = Int

type record Model =
  { count : Count
  }

let subscribe : Model -> Sequence (Sub Msg)
let subscribe _model =
  [ subs.onResize { w h -> Resized { width = w, height = h } }
  ]

let update : Msg, Model -> Next Model (Sequence (Cmd Msg))
let update msg model =
  when msg is
    | Resized _ -> tea.next model []
    | ViewMsg viewMsg -> viewUpdate viewMsg model

let viewUpdate : ViewMsg, Model -> Next Model (Sequence (Cmd Msg))
let viewUpdate msg model =
  debug
    # TODO: Do we provide an API to serialize types for viewing?
    debug.log "viewUpdate: {m:s}" {m=msg}

  when msg is
    | ViewMsg Inc ->
      let _newCount : Count
      let _newCount = model.count + 1
      tea.next
        { ...model
        , count = model.count + 1
        }
        []

let view : Model -> (Sequence (ViewNode ViewMsg))
let view { count } =
  let c = fmt.format "Count: {c:i}" {c=count}
  let t = tea
  [ t.for [ t.range 0 5 ]
    [ t.button [t.onClick Inc] [t.text c] ]
  ]

  """tea
  [ for [ range 0 5 ]
    [ button [ onClick Inc ] [ text t ]
    ]
  ]
  """

  # TODO: Make DSLs nicer with builders?
  # tea.div
  #   []
  #   [ tea.button [ tea.onClick Inc ] [ tea.text t ]
  #   ]
  # ```tea
  # (for (range 0 5)
  #   (button (onClick Inc) (text c)))
  # ```
  # ```tea
  # [ for (range 0 5)
  #   [ button [onClick Inc] [text c] ]
  # ]
  # ```
  # with tea
  #   [ for [range 0 5]
  #     [ button [onClick Inc] [text c] ]
  #   ]
  # with tea
  #   [ :for [range 0 5]
  #     [ :button [:onClick Inc] [:text c] ]
  #   ]


###

module "canapea/experiments/ui"
  exposing
    | +SubscribeToSystemEvents
    | +SubscribeToView
    | +UpdateView

type constructor concept +SubscribeToSystemEvents =
  debug.todo _

type constructor concept +SubscribeToView =
  debug.todo _

type constructor concept +UpdateView =
  debug.todo _



module "experimental/tea"
  exposing
    | Cmds
    | Next
    | Subs
    | ViewNode
    | ViewNodes
    | program
    | button
    | div
    | onClick
    | text

import capability "canapea/experiments/ui"
  exposing
    | +SubscribeToSystemEvents
    | +SubscribeToUserEvents
    | +UpdateView

type ViewNode msg =
  | ViewNode msg

type Cmd msg =
  | Cmd msg

type Sub msg =
  | Sub msg

type Next m msg
  | Next m msg


# TODO: Support `type alias`? Does this create a new type?
type alias Cmds msg = Sequence (Cmd msg)
type alias Subs msg = Sequence (Sub msg)
type alias ViewNodes = Sequence (ViewNode msg)

let program :
  TeaProgram
    model
    (<^SubscribeToUserEvents,^UpdateView> -> (model -> ViewNodes msg))
    (msg, model -> model)
    (<*SubscribeToSystemEvents> -> (model -> Subs msg))
let program model view update subs =
  let root = view model
  let { nodes, subs } = traverse [ root ]
  let dom = render nodes subs
  debug.todo _


let onClick msg =
  debug.todo _
