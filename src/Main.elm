import Html exposing (..)
import Html.Attributes exposing (..)
import Date.Extra.Format exposing (format)
import Date exposing (Date, fromTime, now)
import Task
import Time
import Date.Extra.Config.Config_en_us exposing (config)

main : Program Never Model Msg
main = program { init = init, view = view, update = update, subscriptions = subscriptions }

type alias Model = Date

init : (Model, Cmd Msg)
init = (fromTime 0, Task.perform UpdateDate now)

type Msg = UpdateDate Date

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateDate newDate -> (newDate, Cmd.none)

view : Model -> Html Msg
view model =
    div [class "clock"] [
         div [class "time"] [text (format config "%H:%M:%S" model)],
         div [class "date"] [text (format config "%a, %B %-@d %Y" model)]
        ]

subscriptions : Model -> Sub Msg
subscriptions _ = Time.every Time.second (fromTime >> UpdateDate)
