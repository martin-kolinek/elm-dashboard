import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Date.Extra.Format exposing (format)
import Date exposing (Date, fromTime, now)
import Task
import Time
import Date.Extra.Config.Config_en_us exposing (config)
import BasicAuth
import HttpBuilder
import Json.Decode
import Http

main : Program Never Model Msg
main = program { init = init, view = view, update = update, subscriptions = subscriptions }

type alias NewsItem = {
        id : Int,
        uri: String,
        title: String
    }

type alias Model = {
        currentDate: Date,
        currentNews: List NewsItem
    }

init : (Model, Cmd Msg)
init = (initModel, Task.perform UpdateDate now)

initModel : Model
initModel = {
        currentDate = fromTime 0,
        currentNews = [ {id = 3, uri = "https://google.com", title = "Test news item" }]
    }

type Msg = UpdateDate Date | SetItems (List NewsItem)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateDate newDate -> ({ model | currentDate = newDate }, Cmd.none)
        SetItems items -> ({model | currentNews = items}, Cmd.none)

fetchNews : Cmd Msg
fetchNews =
    HttpBuilder.get "https://sps2010.erninet.ch/news/Services/_vti_bin/listdata.svc/Posts()?$top=20&$orderby=Id desc" |>
    HttpBuilder.withExpect (Http.expectJson newsItemsDecoder) |>
    HttpBuilder.withCredentials |>
    HttpBuilder.withHeader "Accept" "application/json" |>
    HttpBuilder.send parseResponse

parseResponse : Result Http.Error (List NewsItem) -> Msg
parseResponse response = case response of
    Ok items -> SetItems items
    Err _ -> SetItems []

newsItemsDecoder : Json.Decode.Decoder (List NewsItem)
newsItemsDecoder = Json.Decode.field "d" (Json.Decode.list newsItemDecoder)

newsItemDecoder : Json.Decode.Decoder NewsItem
newsItemDecoder = Json.Decode.map3 NewsItem
                  (Json.Decode.field "Id" Json.Decode.int)
                  (Json.Decode.field "__metadata" (Json.Decode.field "uri" Json.Decode.string))
                  (Json.Decode.field "Title" Json.Decode.string)

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
