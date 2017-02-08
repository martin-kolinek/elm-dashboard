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

type SharepointCredentials = Unknown {
        user: String,
        password: String
    } |
    Known {
        user: String,
        password: String
    }

type alias Model = {
        currentDate: Date,
        currentNews: List NewsItem,
        sharepointCredentials: SharepointCredentials
    }

init : (Model, Cmd Msg)
init = (initModel, Task.perform UpdateDate now)

initModel : Model
initModel = {
        currentDate = fromTime 0,
        currentNews = [ {id = 3, uri = "https://google.com", title = "Test news item" }],
        sharepointCredentials = Unknown {user = "", password = ""}
    }

type Msg = UpdateDate Date | SharepointName String | SharepointPassword String | ConfirmCredentials | SetItems (List NewsItem)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateDate newDate -> ({ model | currentDate = newDate }, Cmd.none)
        SharepointName newUser -> (updateCredentials (\cred -> {cred | user = newUser}) model, Cmd.none)
        SharepointPassword newPassword -> (updateCredentials (\cred -> {cred | password = newPassword}) model, Cmd.none)
        ConfirmCredentials -> let newModel = confirmCredentials model in (newModel, fetchNews newModel)
        SetItems items -> ({model | currentNews = items}, Cmd.none)

updateCredentials : ({user: String, password: String} -> {user: String, password: String}) -> Model -> Model
updateCredentials updateCred model = case model.sharepointCredentials of
    Known _ -> model
    Unknown cred -> { model | sharepointCredentials = Unknown (updateCred cred)}

confirmCredentials : Model -> Model
confirmCredentials model = case model.sharepointCredentials of
    Known _ -> model
    Unknown cred -> {model | sharepointCredentials = Known cred}

fetchNews : Model -> Cmd Msg
fetchNews model =
    HttpBuilder.get "https://sps2010.erninet.ch/news/Services/_vti_bin/listdata.svc/Posts()?$top=20&$orderby=Id desc" |>
    HttpBuilder.withExpect (Http.expectJson newsItemsDecoder) |>
    HttpBuilder.withCredentials |>
    HttpBuilder.withHeader "Accept" "application/json" |>
    HttpBuilder.send parseResponse

addAuthorizationToken : Model -> HttpBuilder.RequestBuilder a -> HttpBuilder.RequestBuilder a
addAuthorizationToken model = case model.sharepointCredentials of
    Known cred -> HttpBuilder.withHeader "Authorization" ("Basic " ++ BasicAuth.buildAuthorizationToken cred.user cred.password)
    _ -> identity

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
              viewNewsItems model,
              viewCredentials model
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

viewCredentials : Model -> Html Msg
viewCredentials { sharepointCredentials } = case sharepointCredentials of
    Unknown { user, password } ->
        div [class "shroud"] [
             Html.form [class "credentials", onSubmit ConfirmCredentials] [
                  h1 [] [text "Enter Sharepoint Credentials"],
                  input [ type_ "text", placeholder "User name", onInput SharepointName] [],
                  input [ type_ "password", placeholder "Password", onInput SharepointPassword] [],
                  button [] [text "Confirm"]
                 ]
            ]
    Known _ -> text ""

subscriptions : Model -> Sub Msg
subscriptions _ = Time.every Time.second (fromTime >> UpdateDate)
