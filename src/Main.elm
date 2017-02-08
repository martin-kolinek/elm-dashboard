import Html exposing (..)
import Html.Attributes exposing (..)
import Date.Extra.Format exposing (format)
import Date exposing (Date, fromTime, now)
import Task
import Time
import Date.Extra.Config.Config_en_us exposing (config)

main : Program Never Model Msg
main = program { init = init, view = view, update = update, subscriptions = subscriptions }

type alias NewsItem = {
        id : Int,
        uri: String,
        title: String
    }

type alias Model = {
        currentDate : Date,
        currentNews : List NewsItem
    }

init : (Model, Cmd Msg)
init = ({ currentDate = fromTime 0, currentNews = [ {id = 3, uri = "https://google.com", title = "Test news item" }]}, Task.perform UpdateDate now)

type Msg = UpdateDate Date

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateDate newDate -> ({ model | currentDate = newDate }, Cmd.none)

view : Model -> Html Msg
view model = div [] [
              viewClock model,
              viewNewsItems model
             ]

viewClock : Model -> Html Msg
viewClock { currentDate } =
    div [class "clock dashboard-item"] [
         div [class "time"] [text (format config "%H:%M:%S" currentDate)],
         div [class "date"] [text (format config "%a, %B %-@d %Y" currentDate)]
        ]

viewNewsItems : Model -> Html Msg
viewNewsItems { currentNews } =
    div [class "news dashboard-item"] (h1 [] [text "Latest news"] :: (List.map viewNewsItem currentNews))

viewNewsItem : NewsItem -> Html Msg
viewNewsItem { uri, title } =
    div [class "news-item"] [
         a [href uri, target "_blank"] [text title]
        ]

subscriptions : Model -> Sub Msg
subscriptions _ = Time.every Time.second (fromTime >> UpdateDate)
