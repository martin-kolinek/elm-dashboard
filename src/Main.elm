import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Date.Extra.Format exposing (format)
import Date exposing (Date, fromTime, now)
import Task
import Time
import Date.Extra.Config.Config_en_us exposing (config)
import HttpBuilder
import Json.Decode
import Http
import Set
import LocalStorage

main : Program Never Model Msg
main = program { init = init, view = view, update = update, subscriptions = subscriptions }

type alias NewsItem = {
        id : Int,
        uri: String,
        title: String
    }

type News = NewsItems (List NewsItem) | NewsProblem String

type alias Model = {
        currentDate: Date,
        currentNews: News,
        dismissedNews: Set.Set Int
    }

init : (Model, Cmd Msg)
init = (initModel, Cmd.batch [Task.perform UpdateDate now, fetchNews, LocalStorage.loadDismissedNews ()])

initModel : Model
initModel = {
        currentDate = fromTime 0,
        currentNews = NewsItems [],
        dismissedNews = Set.empty
    }

type Msg = UpdateDate Date | SetNews (News) | UpdateNews | DismissNewsItem Int | UpdateDismissedNews (List Int)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateDate newDate -> ({ model | currentDate = newDate }, Cmd.none)
        SetNews news -> ({model | currentNews = news}, Cmd.none)
        UpdateNews -> (model, fetchNews)
        DismissNewsItem id -> updateDismissedNews model (Set.insert id model.dismissedNews)
        UpdateDismissedNews ids -> updateDismissedNews model (Set.union (Set.fromList ids) model.dismissedNews)

updateDismissedNews : Model -> Set.Set Int -> (Model, Cmd msg)
updateDismissedNews model newDismissedNews = ( {model | dismissedNews = newDismissedNews}, LocalStorage.saveDismissedNews (Set.toList newDismissedNews))

fetchNews : Cmd Msg
fetchNews =
    HttpBuilder.get "https://sps2010.erninet.ch/news/Services/_vti_bin/listdata.svc/Posts()?$top=20&$orderby=Id desc" |>
    HttpBuilder.withExpect (Http.expectJson newsItemsDecoder) |>
    HttpBuilder.withCredentials |>
    HttpBuilder.withHeader "Accept" "application/json" |>
    HttpBuilder.send parseResponse

parseResponse : Result Http.Error (List NewsItem) -> Msg
parseResponse response = case response of
    Ok items -> SetNews (NewsItems items)
    Err (Http.BadUrl _) -> SetNews (NewsProblem "Wrong URL for some reason")
    Err Http.Timeout -> SetNews (NewsProblem "Timeout occurred")
    Err Http.NetworkError -> SetNews (NewsProblem "Network error (do you have CorsE enabled?)")
    Err (Http.BadStatus {status}) -> SetNews (NewsProblem ("Http problem: " ++ (toString status.code) ++ " " ++ status.message))
    Err (Http.BadPayload _ _) -> SetNews (NewsProblem "Unexpected response format")

newsItemsDecoder : Json.Decode.Decoder (List NewsItem)
newsItemsDecoder = Json.Decode.field "d" (Json.Decode.list newsItemDecoder)

newsItemDecoder : Json.Decode.Decoder NewsItem
newsItemDecoder = Json.Decode.map3 NewsItem
                  (Json.Decode.field "Id" Json.Decode.int)
                  (Json.Decode.field "__metadata" (Json.Decode.field "uri" Json.Decode.string))
                  (Json.Decode.field "Title" Json.Decode.string)

view : Model -> Html Msg
view model = div [class "dashboard-container"] [
              viewClock model,
              viewNews model
             ]

viewClock : Model -> Html Msg
viewClock { currentDate } =
    div [class "clock dashboard-item"] [
         div [class "time"] [text (format config "%H:%M:%S" currentDate)],
         div [class "date"] [text (format config "%a, %B %-@d %Y" currentDate)]
        ]

findVisibleNews : List NewsItem -> Set.Set Int -> List NewsItem
findVisibleNews newsItems dismissedNews = List.filter (\x -> not (Set.member x.id dismissedNews)) newsItems

viewNews : Model -> Html Msg
viewNews { currentNews, dismissedNews } = div [class "news dashboard-item"]
    (case currentNews of
         NewsItems newsItems -> case findVisibleNews newsItems dismissedNews of
             [] -> [h1 [] [text "No recent news"]]
             visibleNews -> (h1 [] [text "Latest news"] :: (List.map viewNewsItem visibleNews))
         NewsProblem problem -> [h1 [class "news-error"] [text "Unable to fetch news"], p [class "news-error"] [text problem]]
    )

viewNewsItem : NewsItem -> Html Msg
viewNewsItem { uri, title, id } =
    div [class "news-item"] [
         a [href uri, target "_blank"] [text title],
         span [class "dismiss-news", onClick (DismissNewsItem id)] []
        ]

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.batch [
    Time.every Time.second (fromTime >> UpdateDate),
    Time.every (2 * Time.minute) (always UpdateNews),
    LocalStorage.dismissedNews (UpdateDismissedNews)
  ]
