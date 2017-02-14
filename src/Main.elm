import Html exposing (..)
import Html.Attributes exposing (..)
import Navigation
import News
import Calendar
import Clock

main : Program Never Model Msg
main = Navigation.program (always LocationChange) { init = init, view = view, update = update, subscriptions = subscriptions }

type alias Model = {
        clock: Clock.Model,
        news: News.Model,
        calendar: Calendar.Model
    }

init : Navigation.Location -> (Model, Cmd Msg)
init location =
    (initModel,
    Cmd.batch [
          Clock.initCmd |> Cmd.map ClockMsg,
          News.initCmd |> Cmd.map NewsMsg,
          Calendar.initCmd location |> Cmd.map CalendarMsg
         ])

initModel : Model
initModel = {
        clock = Clock.initModel,
        news = News.initModel,
        calendar = Calendar.initModel
    }

type Msg = ClockMsg Clock.Msg | NewsMsg News.Msg | CalendarMsg Calendar.Msg | LocationChange

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ClockMsg clockMsg -> let (clockModel, clockCmd) = Clock.update clockMsg model.clock in ({ model | clock = clockModel }, clockCmd |> Cmd.map ClockMsg)
        CalendarMsg calMsg -> let (calModel, calCmd) = Calendar.update calMsg model.calendar in ({ model | calendar = calModel }, calCmd |> Cmd.map CalendarMsg)
        NewsMsg newsMsg -> let (newsModel, newsCmd) = News.update newsMsg model.news in ({ model | news = newsModel }, newsCmd |> Cmd.map NewsMsg)
        LocationChange -> (model, Cmd.none)

view : Model -> Html Msg
view model = div [class "dashboard-container"] [
              Clock.view model.clock |> Html.map ClockMsg,
              News.view model.news |> Html.map NewsMsg,
              Calendar.view model.calendar |> Html.map CalendarMsg
             ]

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch [
    Clock.subscriptions |> Sub.map ClockMsg,
    News.subscriptions model.news |> Sub.map NewsMsg
  ]
