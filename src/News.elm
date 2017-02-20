module News exposing (Model, Msg, view, subscriptions, update, initModel, initCmd)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Set
import LocalStorage
import HttpBuilder
import Http
import Json.Decode
import Time
import Date
import Regex
import Date.Extra

categories : List String
categories = ["Management", "strategy2020", "People", "Customer", "Projects", "Services", "Corporate"]

createFetchUrl : String -> String
createFetchUrl category =
    "https://sps2010.erninet.ch/news/" ++ category ++ "/_vti_bin/listdata.svc/Posts()?$top=20&$orderby=Id desc"

createItemUrl : String -> Int -> String
createItemUrl category id =
    "https://sps2010.erninet.ch/news/" ++ category ++ "/Lists/Posts/ViewPost.aspx?ID=" ++ toString id

type alias NewsItem =
    {
        id : Int,
        category: String,
        title: String,
        published: Date.Date
    }

type alias News = Result String (List NewsItem)

type alias Model =
    {
        currentNews: News,
        dismissedNews: Set.Set (String, Int)
    }

type Msg = SetNews (News) | UpdateNews | DismissNewsItem NewsItem | UpdateDismissedNews (List (String, Int))

initModel : Model
initModel =
    {
        currentNews = Ok [],
        dismissedNews = Set.empty
    }

initCmd : Cmd Msg
initCmd = Cmd.batch
  (LocalStorage.loadDismissedNews () :: List.map fetchNews categories)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetNews news -> (updateCurrentNews model news, Cmd.none)
        UpdateNews -> (model, Cmd.batch (List.map fetchNews categories))
        DismissNewsItem { id, category } -> updateDismissedNews model (Set.insert (category, id) model.dismissedNews)
        UpdateDismissedNews dismissedItems -> updateDismissedNews model (Set.union (Set.fromList dismissedItems) model.dismissedNews)

updateCurrentNews : Model -> News -> Model
updateCurrentNews model newNews =
    case (model.currentNews, newNews) of
        (Ok oldNewsItems, Ok newNewsItems) ->
            let newKeys = Set.fromList (List.map (\x -> (x.category, x.id)) newNewsItems)
                filteredOldNews = List.filter (\x -> not (Set.member (x.category, x.id) newKeys)) oldNewsItems
            in { model | currentNews = Ok (newNewsItems ++ filteredOldNews) }
        (old, new) -> { model | currentNews = old |> Result.andThen (always new) }

updateDismissedNews : Model -> Set.Set (String, Int) -> (Model, Cmd msg)
updateDismissedNews model newDismissedNews = ( {model | dismissedNews = newDismissedNews}, LocalStorage.saveDismissedNews (Set.toList newDismissedNews))

fetchNews : String -> Cmd Msg
fetchNews category =
    HttpBuilder.get (createFetchUrl category) |>
    HttpBuilder.withExpect (Http.expectJson (newsItemsDecoder category)) |>
    HttpBuilder.withCredentials |>
    HttpBuilder.withHeader "Accept" "application/json" |>
    HttpBuilder.send parseResponse

parseResponse : Result Http.Error (List NewsItem) -> Msg
parseResponse response = case response of
    Ok items -> SetNews (Ok items)
    Err (Http.BadUrl _) -> SetNews (Err "Wrong URL for some reason")
    Err Http.Timeout -> SetNews (Err "Timeout occurred")
    Err Http.NetworkError -> SetNews (Err "Network error (do you have CorsE enabled?)")
    Err (Http.BadStatus {status}) -> SetNews (Err ("Http problem: " ++ (toString status.code) ++ " " ++ status.message))
    Err (Http.BadPayload _ _) -> SetNews (Err "Unexpected response format")

newsItemsDecoder : String -> Json.Decode.Decoder (List NewsItem)
newsItemsDecoder category = Json.Decode.field "d" (Json.Decode.list (newsItemDecoder category))

newsItemDecoder : String -> Json.Decode.Decoder NewsItem
newsItemDecoder category = Json.Decode.map4 NewsItem
                  (Json.Decode.field "Id" Json.Decode.int)
                  (Json.Decode.succeed category)
                  (Json.Decode.field "Title" Json.Decode.string)
                  (Json.Decode.field "Published" (Json.Decode.string |> Json.Decode.andThen parseDateString))

parseDateString : String -> Json.Decode.Decoder Date.Date
parseDateString str =
    let rgx = Regex.regex "\\d+"
        matches = Regex.find (Regex.AtMost 1) rgx str
        result = matches |>
                 List.head |>
                 Result.fromMaybe "Not found" |>
                 Result.map .match |>
                 Result.andThen String.toInt
    in case result of
           Ok res -> Json.Decode.succeed (Date.fromTime (toFloat res))
           Err err -> Json.Decode.fail err

findVisibleNews : List NewsItem -> Set.Set (String, Int) -> List NewsItem
findVisibleNews newsItems dismissedNews =
    newsItems |>
    List.filter (\x -> not (Set.member (x.category, x.id) dismissedNews)) |>
    List.sortBy (.published >> Date.toTime >> negate) |>
    List.take 8

view : Model -> Html Msg
view { currentNews, dismissedNews } = div [class "news dashboard-item"]
    (case currentNews of
         Ok newsItems -> case findVisibleNews newsItems dismissedNews of
             [] -> [h1 [] [text "No Recent News"]]
             visibleNews -> (h1 [] [text "Latest News"] :: (List.map viewNewsItem visibleNews))
         Err problem -> [h1 [class "news-error"] [text "Unable to fetch news"], p [class "news-error"] [text problem]]
    )

viewNewsItem : NewsItem -> Html Msg
viewNewsItem model =
    div [class "news-item"] [
         span [class "news-time"] [text (Date.Extra.toFormattedString "EEE, MMM dd yyyy" model.published)],
         a [href (createItemUrl model.category model.id), target "_blank", title model.title] [text model.title],
         span [class "dismiss-news", onClick (DismissNewsItem model)] []
        ]

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.batch [
    Time.every (2 * Time.minute) (always UpdateNews),
    LocalStorage.dismissedNews (UpdateDismissedNews)
  ]
