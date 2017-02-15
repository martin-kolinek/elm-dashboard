module Clock exposing (Model, Msg, initModel, initCmd, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes exposing (..)
import Date
import Task
import Time
import Date.Extra

type alias Model =
    {
        currentDate: Date.Date
    }

type Msg = UpdateDate Date.Date

initModel : Model
initModel = { currentDate = Date.fromTime 0 }

initCmd : Cmd Msg
initCmd = Task.perform UpdateDate Date.now

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateDate newDate -> ({ model | currentDate = newDate }, Cmd.none)

view : Model -> Html Msg
view { currentDate } =
    div [class "clock dashboard-item"] [
         div [class "time"] [text (Date.Extra.toFormattedString "HH:mm:ss" currentDate)],
         div [class "date"] [text (Date.Extra.toFormattedString "EEE, MMMM ddd yyyy" currentDate)]
        ]

subscriptions : Sub Msg
subscriptions = Time.every Time.second (Date.fromTime >> UpdateDate)

