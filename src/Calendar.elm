module Calendar exposing (Model, Msg, initModel, initCmd, update, view)

import Html exposing (..)
import OAuth
import Http
import Navigation
import HttpBuilder

microsoftAuthClient : OAuth.Client
microsoftAuthClient =
    OAuth.newClient
        {
            authorizeUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
            tokenUrl = "",
            validateUrl = ""
        }
        {
            clientId = "f4fbc084-0ef2-4ef6-800a-35305e7bddb4",
            scopes = ["User.Read", "Calendars.Read"],
            redirectUrl = "http://localhost:3000",
            authFlow = OAuth.Implicit
        }

type alias Model =
    {
        microsoftOauthToken: Maybe OAuth.Token,
        calendarString: String
    }

type Msg = MicrosoftAuthorize OAuth.Token | SetCalendar String | RequestMicrosoftAuthorization

initModel : Model
initModel = {microsoftOauthToken = Nothing, calendarString = "No calendar"}

initCmd : Navigation.Location -> Cmd Msg
initCmd location = OAuth.init microsoftAuthClient location |> Cmd.map authResultToCmd

authResultToCmd : Result Http.Error OAuth.Token -> Msg
authResultToCmd result = case result of
    Err x -> RequestMicrosoftAuthorization
    Ok token -> MicrosoftAuthorize token

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        MicrosoftAuthorize token -> let newModel = { model | microsoftOauthToken = Just token } in (newModel, loadCalendar newModel)
        SetCalendar str -> ({ model | calendarString = str}, Cmd.none)
        RequestMicrosoftAuthorization -> (model, microsoftAuthorize)

loadCalendar : Model -> Cmd Msg
loadCalendar model = case model.microsoftOauthToken of
    Nothing -> microsoftAuthorize
    Just (token) -> case token of
        OAuth.Validated tokenString ->
            HttpBuilder.get "https://graph.microsoft.com/v1.0/me/calendarView?StartDateTime=2017-01-01&EndDateTime=2017-01-31" |>
            HttpBuilder.withHeader "Authorization" ("Bearer " ++ tokenString) |>
            HttpBuilder.withExpect (Http.expectString) |>
            HttpBuilder.send parseCalendarResponse

microsoftAuthorize : Cmd Msg
microsoftAuthorize = Navigation.load (OAuth.buildAuthUrl microsoftAuthClient)

parseCalendarResponse : Result Http.Error String -> Msg
parseCalendarResponse response = case response of
    Ok str -> SetCalendar str
    Err (Http.BadStatus resp) as x -> if resp.status.code == 401 then RequestMicrosoftAuthorization else SetCalendar (toString x)
    Err x -> SetCalendar ("Parse cal resp " ++ toString x)

view : Model -> Html Msg
view model = div [] [text (model.calendarString ++ toString model.microsoftOauthToken)]
