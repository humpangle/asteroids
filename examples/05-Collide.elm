module Main exposing (main)

import AnimationFrame
import Html exposing (Html)
import Html.Attributes
import Mouse
import Time exposing (Time)


-- project modules

import Geometry.Polygon as Polygon exposing (Polygon)
import Geometry.Vector as Vector exposing (Vector, Point)
import Physics exposing (Movement, Collidable)
import Screen
import Types exposing (Moving, Positioned, Radians)
import Util exposing (transformPoints, wrapPosition)


main : Program Never (List (List Disk)) Msg
main =
    Html.program
        { init = ( init, Cmd.none )
        , update = \x r -> ( update x r, Cmd.none )
        , view =
            List.head
                >> Maybe.map
                    (List.map (transformPolygon >> (,,) 1 True)
                        >> Screen.render screenSize
                        >> viewContainer
                    )
                >> Maybe.withDefault (Html.text "")
        , subscriptions =
            Sub.batch
                [ AnimationFrame.diffs (Tick << Time.inSeconds)
                , Mouse.downs (always Next)
                ]
                |> always
        }


viewContainer : Html a -> Html a
viewContainer content =
    Html.div
        [ Html.Attributes.style
            [ ( "height", "100vh" )
            , ( "fill", "none" )
            , ( "stroke", "gray" )
            , ( "stroke-width", "2px" )
            ]
        ]
        [ content
        ]


init : List (List Disk)
init =
    let
        pairs =
            [ [ toDisk ( 300, 100 ) ( 300, 300 ) (pi / 3)
              , toDisk ( 600, 400 ) ( 0, 0 ) 0
              ]
            , [ toDisk ( 100, 100 ) ( 300, 300 ) (pi / 3)
              , toDisk ( 300, 300 ) ( 200, 200 ) 0
              ]
            , [ toDisk ( 300, 100 ) ( 300, 330 ) 0
              , toDisk ( 600, 400 ) ( 0, 0 ) 0
              ]
            , [ toDisk ( 300, 100 ) ( 300, 430 ) (pi / 3)
              , toDisk ( 600, 400 ) ( 0, 0 ) 0
              ]
            , [ toDisk ( 300, 100 ) ( 300, 300 ) (pi / 3)
              , toDisk ( 400, 600 ) ( 200, -200 ) 0
              ]
            , [ toDisk ( 300, 100 ) ( 350, 50 ) (pi / 8)
              , toDisk ( 900, 100 ) ( -150, 70 ) (pi / -2)
              ]
            , [ toDisk ( 300, 100 ) ( 250, 100 ) (pi / 3)
              , toDisk ( 900, 100 ) ( -250, 100 ) (pi / -3)
              ]
            , [ toDisk ( 300, 100 ) ( 350, 270 ) (pi / -5)
              , toDisk ( 900, 700 ) ( -150, -150 ) (pi / 2)
              ]
            ]
    in
        List.map (toPair 50 50) pairs
            ++ List.map (toPair 30 50) pairs
            ++ List.map (toPair 50 30) pairs


toPair : Float -> Float -> List (Float -> Disk) -> List Disk
toPair a b pair =
    case pair of
        [ f, g ] ->
            [ f a, g b ]

        _ ->
            []



--


type alias Disk =
    Collidable {}


toDisk : Point -> Vector -> Radians -> Float -> Disk
toDisk p v a radius =
    { radius = radius
    , polygon = Polygon.ngon 12 |> List.map (Vector.scale radius)
    , position = p
    , rotation = 0
    , velocity = v
    , angularVelocity = a
    }



--


type Msg
    = Tick Time
    | Next


update : Msg -> List (List Disk) -> List (List Disk)
update msg lists =
    case ( msg, lists ) of
        ( Tick dt, disks :: rest ) ->
            updateDisks dt disks :: rest

        ( Next, _ :: rest ) ->
            rest

        _ ->
            lists


updateDisks : Time -> List Disk -> List Disk
updateDisks dt disks =
    case disks |> List.map (updateMoving dt >> wrapPosition screenSize) of
        [ a, b ] ->
            case Physics.collide 0.9 a b of
                Just ( ma, mb, _ ) ->
                    [ a |> setMovement ma
                    , b |> setMovement mb
                    ]

                Nothing ->
                    [ a, b ]

        x ->
            x


updateMoving : Time -> Moving (Positioned a) -> Moving (Positioned a)
updateMoving dt obj =
    { obj
        | position = obj.position |> Vector.add (obj.velocity |> Vector.scale dt)
        , rotation = obj.rotation + obj.angularVelocity * dt
    }


screenSize : ( Float, Float )
screenSize =
    ( 1200, 900 )


setMovement : Movement -> Moving a -> Moving a
setMovement ( v, av ) a =
    { a | velocity = v, angularVelocity = av }


transformPolygon : Positioned { a | polygon : Polygon } -> Polygon
transformPolygon { polygon, position, rotation } =
    polygon |> transformPoints position rotation
