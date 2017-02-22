import Html exposing (..)
import Html.Events exposing (..)

main : Program Never Model Msg
main = program { init = init, view = view, update = update, subscriptions = subscriptions }

type alias Model = { thingToDisplay: String}
type Msg = ChangeThingToDisplay

init : (Model, Cmd Msg)
init = ({ thingToDisplay = "Hello World"}, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangeThingToDisplay -> ({ model | thingToDisplay = model.thingToDisplay ++ "!" }, Cmd.none)

view : Model -> Html Msg
view model = h1 [onClick ChangeThingToDisplay] [text model.thingToDisplay]

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none
