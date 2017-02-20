module Calendar exposing (Model, Msg, initModel, initCmd, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import OAuth
import Http
import Navigation
import HttpBuilder
import Date
import Json.Decode
import Date.Extra
import Task

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
        microsoftOAuthToken: OAuth.Token,
        calendar: Calendar
    }

type alias CalendarItem =
    {
        startDate: Date.Date,
        title: String
    }

type Calendar = CalendarItems (List CalendarItem) | CalendarError String

type Msg = MicrosoftAuthorize OAuth.Token | SetCalendar Calendar | RequestMicrosoftAuthorization

initModel : Model
initModel = {microsoftOAuthToken = OAuth.Validated "", calendar = CalendarItems []}

initCmd : Navigation.Location -> Cmd Msg
initCmd location = OAuth.init microsoftAuthClient location |> Cmd.map authResultToCmd

authResultToCmd : Result Http.Error OAuth.Token -> Msg
authResultToCmd result = case result of
    Err x -> RequestMicrosoftAuthorization
    Ok token -> MicrosoftAuthorize token

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        MicrosoftAuthorize token -> let newModel = { model | microsoftOAuthToken = token } in (newModel, loadCalendar newModel)
        SetCalendar calendar -> ({ model | calendar = calendar }, Cmd.none)
        RequestMicrosoftAuthorization -> (model, microsoftAuthorize)

loadCalendar : Model -> Cmd Msg
loadCalendar model = Task.attempt parseCalendarResponse (Date.now |> Task.andThen (loadCalendarTask model))

createQueryParams : Date.Date -> List (String, String)
createQueryParams date = [
    ("StartDateTime", Date.Extra.toUtcIsoString date),
    ("EndDateTime", Date.Extra.toUtcIsoString (Date.Extra.add Date.Extra.Week 2 date)),
    ("$orderBy", "start/dateTime")]

loadCalendarTask : Model -> Date.Date -> Task.Task Http.Error (List CalendarItem)
loadCalendarTask model currentDate = case model.microsoftOAuthToken of
    OAuth.Validated tokenString ->
        HttpBuilder.get "https://graph.microsoft.com/v1.0/me/calendarView" |>
        HttpBuilder.withQueryParams (createQueryParams currentDate) |>
        HttpBuilder.withHeader "Authorization" ("Bearer " ++ tokenString) |>
        HttpBuilder.withExpect (Http.expectJson calendarItemsDecoder) |>
        HttpBuilder.toTask

calendarItemsDecoder : Json.Decode.Decoder (List CalendarItem)
calendarItemsDecoder = Json.Decode.field "value" (Json.Decode.list (
    Json.Decode.map2 CalendarItem
        (Json.Decode.field "start" (Json.Decode.field "dateTime" dateDecoder))
        (Json.Decode.field "subject" Json.Decode.string)
    ))

dateDecoder : Json.Decode.Decoder Date.Date
dateDecoder = Json.Decode.string |>
              Json.Decode.andThen (\x -> case Date.Extra.fromIsoString (x++"Z") of
                                             Just d -> Json.Decode.succeed d
                                             Nothing -> Json.Decode.fail "Not a valid date")

microsoftAuthorize : Cmd Msg
microsoftAuthorize = Navigation.load (OAuth.buildAuthUrl microsoftAuthClient)

parseCalendarResponse : Result Http.Error (List CalendarItem) -> Msg
parseCalendarResponse response = case response of
    Ok lst -> SetCalendar (CalendarItems lst)
    Err (Http.BadStatus resp) as x -> if resp.status.code == 401 then RequestMicrosoftAuthorization else SetCalendar (CalendarError (toString x))
    Err x -> SetCalendar (CalendarError ("Parse cal resp " ++ toString x))

view : Model -> Html Msg
view model = div [class "calendar dashboard-item"] (h1 [] [text "Upcoming events"] :: case model.calendar of
    CalendarItems items -> List.map viewItem items
    CalendarError err -> [text err])

viewItem : CalendarItem -> Html Msg
viewItem { startDate, title } = div [class "calendar-item"] [span [class "calendar-time"] [text (Date.Extra.toFormattedString "EEE, MMM dd, HH:mm" startDate)], text title]
