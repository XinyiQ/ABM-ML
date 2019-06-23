;AOI is 16km*4km, here each patch reprents 26m*26m
extensions [gis csv]

breed [residents resident]
breed [tourists tourist]

turtles-own [stay-duration               ;Owned only by tourists
             activity                    ;1-working, 2-gardening, 3-picnicing, 4-hiking, 5-playing, 6-sunbathing
             prisk                       ;exposure-risk (related to activity. which also affected by tem and pre )
             exprisk                     ;exposure-risk (related to body procaution,dressing, directly influenced by temperature)
             awareness                   ;vulnerability (related to personal consciousness about "Tick" and "Tick-bite")
             bite-statu                  ;True or False
             bite-times                  ;How many times it got biten
             Frisk]                      ;Final risk

patches-own [landuse                    ;20-built-up, 60-forest, 61-sand, 62-others
             hazard                     ;Based tick abundance adding seasonal change
             tabundance                 ;Tick abundance (how many ticks in each singel patch, data from "Hazard_map.asc"), from 0 to 999
             patch-bite-count           ;How many tick-bite happened in that patch
             patch-agent-count          ;How many turtles have been in that patch
             ac1-count                  ;With activity 1, how many people got bitten in that patch
             ac2-count                  ;With activity 2, how many people got bitten in that patch
             ac3-count                  ;With activity 3, how many people got bitten in that patch
             ac4-count                  ;With activity 4, how many people got bitten in that patch
             ac5-count                  ;With activity 5, how many people got bitten in that patch
             ac6-count]                 ;With activity 6, how many people got bitten in that patch

globals [landuse-list
         landuse-dataset
         shape-dataset
         tabundance-dataset
         season                         ;2-Spring,3-Summer,4-Fall
         precipitation                  ;Daily precipitation amount in 0.1 mm over the period 08.00 preceding day - 08.00 UTC present day
         temperature                    ;Daily mean temperature in (0.1 degrees Celsius)
         whole-bite-count               ;How many tick-bite events happened
         new-bites                      ;How many tick-bite events happened in perticular tick(time)
         output-file-1                  ;Output patch-bite-count
         output-file-2                  ;Output patch-agent-count
         output-file-3                  ;Output ac1-count
         output-file-4                  ;Output ac2-count
         output-file-5                  ;Output ac3-count
         output-file-6                  ;Output ac4-count
         output-file-7                  ;Output ac5-count
         output-file-8]                 ;Output ac6-count

to setup
  clear-all
  file-close-all
  setup-environment
  setup-agents
  reset-ticks
end

to setup-agents
  create-residents 940                                            ; load residents with number of 940
    ask residents [move-to one-of patches with [landuse = 20]     ; initially ask residents stay in bulit-up area
                   set color white + 2                            ; set the color of residents black with human shape
                   set shape "person"
                   set awareness one-of (range 0.5 10 0.5) ]      ;set initial awareness of residents from 0.5 to 10, it can't be 0 as we use 1/awareness as agents vulnerability

  create-tourists 960                                             ; load residents with number of 940
    ask tourists [move-to one-of patches with [landuse > 0]       ; initially ask residents stay in any patch except bulit-up area
                  set color white set shape "person"              ; set the color of residents grey with human shape
                  set awareness one-of (range 0.5 10 0.5)         ; set initial awareness of residents from 0.5 to 10
                  set stay-duration (random 5 + 1)]               ; set the travel days of tourists randomly
end

to setup-environment
   set landuse-dataset gis:load-dataset "Data/Schiermonnikoog/schier_ascii.asc"        ;load the land cover data of Schiermonnikoog
   gis:set-world-envelope (gis:envelope-of landuse-dataset)
   gis:apply-raster landuse-dataset landuse
   ask patches [if landuse = 20 [set pcolor orange]               ; set built-up area color orange
                if landuse = 60 [set pcolor green]                ; set forest area color green
                if landuse = 61 [set pcolor yellow]               ; set sand area color yellow
                if landuse = 62 [set pcolor grey]]                ; set other area color grey

  set shape-dataset gis:load-dataset "Data/Schiermonnikoog/Schier_shape.shp"           ;load the boundary of Schiermonnikoog
  gis:set-drawing-color grey - 2                                                       ;set the boudary color light grey
  gis:draw shape-dataset 2                                                             ;set the Line thickness

  set tabundance-dataset gis:load-dataset "Data/hazard.ASC"                            ;load the tick abundance reference data
  gis:set-world-envelope (gis:envelope-of tabundance-dataset)
  gis:apply-raster tabundance-dataset tabundance
end

to go
     file-open "Data/TP2010.csv"                                                     ; open the Temperature and Precipitation data in 2010
    ; file-open "Data/TP2014.csv"                                                    ; open the Temperature and Precipitation data in 2014


  if file-at-end? [stop]                                                             ; define the model end when file read at end
  let weather csv:from-row file-read-line
  set season item 2 weather                                                          ; load season data, 3rd column in file (1-winter, 2-spring, 3-summer, 4-fall)
  set precipitation item 1 weather                                                   ; load precipitation data, 2nd column in file
  set temperature item 0 weather                                                     ; load temperature data, 1st column in file

  ask residents [
    ifelse ticks mod 7 != 6 and ticks mod 7 != 0                            ;define residents activity
    [set activity one-of [1 2]]                                             ;if weekdays, working or gardening
    [set activity one-of [2 3 4 5 6]]]                                      ;if weekend, gardening or picnicking or hiking or playing or sunbathing
  ask tourists [set activity one-of [3 4 5 6]]                              ;define toursit daily activity one of picnicking or hiking or playing or sunbathing

  move
  risk-set
  count-risk
  tick-bite
  count-bite-times
  adaptive-setting
  count-patch-agent
  count-patch-bite
  count-activity
  count-whole-bite

   if ticks =  269 [
   set output-file-1 gis:patch-dataset patch-bite-count
   gis:store-dataset output-file-1 "Data/OUTPUT/PBC_ascii_2010.asc"

   set output-file-2 gis:patch-dataset patch-agent-count
   gis:store-dataset output-file-2 "Data/OUTPUT/PAC_ascii_2010.asc"

    set output-file-3 gis:patch-dataset ac1-count
   gis:store-dataset output-file-3 "Data/OUTPUT/AC1_ascii_2010.asc"

    set output-file-4 gis:patch-dataset ac2-count
   gis:store-dataset output-file-4 "Data/OUTPUT/AC2_ascii_2010.asc"

    set output-file-5 gis:patch-dataset ac3-count
   gis:store-dataset output-file-5 "Data/OUTPUT/AC3_ascii_2010.asc"

    set output-file-6 gis:patch-dataset ac4-count
   gis:store-dataset output-file-6 "Data/OUTPUT/AC4_ascii_2010.asc"

    set output-file-7 gis:patch-dataset ac5-count
   gis:store-dataset output-file-7 "Data/OUTPUT/AC5_ascii_2010.asc"

    set output-file-8 gis:patch-dataset ac6-count
   gis:store-dataset output-file-8 "Data/OUTPUT/AC6_ascii_2010.asc"
  ]

  tick

  write-to-file
end

to move
  if precipitation < 76 [                         ; 7.6 millmeters defines as heavy rain
                             ask residents with [activity = 1][move-to one-of patches with [landuse = 20]]  ;ask working residents stay in built-up area
                             ask residents with [activity = 2][move-to one-of patches with [landuse = 20 or landuse = 60 or landuse = 62]]    ;ask gardening residnets stay in builtup or forest or other
                             ask turtles with [activity = 3 or activity = 4 or activity = 5][move-to one-of patches with [landuse = 60 or landuse = 61 or landuse = 62]]
                             ask turtles with [activity = 6] [move-to one-of patches with [landuse = 61]]]   ;activity 6-sunbathing-only happens in landuse 61 "sand"
end

to risk-set
  ask turtles [if activity = 1 [set prisk 0.1]
               if activity = 2 [set prisk 5.5]
               if activity = 3 [set prisk 4.0]
               if activity = 4 [set prisk 3.5]
               if activity = 5 [set prisk 4.5]
               if activity = 6 [set prisk 5.0] ]

  ask turtles [if temperature < 70 [ set exprisk 0]                                    ; < 7 degrees Celsius
               if 70 <= temperature  and temperature < 140 [set exprisk 5.5]           ; > = 7 and < 14 degrees Celsius
               if 140 <= temperature and temperature < 180 [set exprisk 6.5]           ; > = 14 and < 18 degrees Celsius
               if 180 <= temperature [set exprisk 7.5]]                                ; > = 18 degrees Celsius


  ask patches [if landuse = 20 or landuse = 60 or landuse = 61 or landuse = 62
                              [                                                                        ;winter excluded
                               if season = 2 [set hazard tabundance * 0.9]                             ;2-spring
                               if season = 3 [set hazard tabundance * 1.2]                             ;3-summer
                               if season = 4 [set hazard tabundance * 0.9]]    ]                       ;4-fall
end

to count-risk
   ask turtles [set Frisk (1 / awareness) * prisk * exprisk * [hazard] of patch-here * 0.01]
end

to tick-bite                                                         ; defines how people got tick-bite
  ask turtles [ifelse Frisk > 25                                     ; here, 25 is calculated from median or average value of awareness/prisk/exprisk/hazard
                [set bite-statu "True"]
                [set bite-statu "False"]]
end

to count-bite-times                                                  ; caculate how many times a residents got tick-bite
  ask residents [ if Frisk > 25
                [set bite-times bite-times + 1]]
end

to adaptive-setting
  ask residents [ if bite-times = 6
    [set awareness awareness * 1.1]                                  ;awareness increased 10 percent
                if bite-times = 8
    [set awareness awareness * 1.2]                                  ;awareness increased more 20 percent
                if bite-times = 10
    [set awareness awareness * 1.2]]                                 ;awareness increased more 20 percent
  ask residents [ if awareness > 15    [set awareness 15 ]]
end

to count-patch-agent
  ask patches [set patch-agent-count (patch-agent-count + count turtles-here)]                    ; records “how many turtles have been that patch”
end

to count-patch-bite
  ask patches [set patch-bite-count patch-bite-count + count turtles-here with [Frisk > 25]]         ;records “how many turtles got bitten in that patch”
end

to count-activity
  ask patches [set ac1-count ac1-count + count turtles-here with [activity = 1 and bite-statu = "True"]    ;based on the “patch-bite-count”, this records “how many times ‘working’ implemented”
               set ac2-count ac2-count + count turtles-here with [activity = 2 and bite-statu = "True"]    ;based on the “patch-bite-count”,this records “how many times ‘gardening’ implemented”
               set ac3-count ac3-count + count turtles-here with [activity = 3 and bite-statu = "True"]    ;based on the “patch-bite-count”,this records “how many times ‘picnicing’ implemented”
               set ac4-count ac4-count + count turtles-here with [activity = 4 and bite-statu = "True"]    ;based on the “patch-bite-count”,this records “how many times ‘hiking’ implemented”
               set ac5-count ac5-count + count turtles-here with [activity = 5 and bite-statu = "True"]    ;based on the “patch-bite-count”,this records “how many times ‘playing’ implemented”
               set ac6-count ac6-count + count turtles-here with [activity = 6 and bite-statu = "True"]]   ;based on the “patch-bite-count”,this records “how many times ‘sunbathing’ implemented”
end

to count-whole-bite
  set whole-bite-count whole-bite-count + count turtles with [bite-statu = "True"]           ;record how many bitten people in a global environment
  set new-bites count turtles with [bite-statu = "True"]                                     ;record how many bitten people in every tick (day)
end


to write-to-file
  file-open "PBC_2010.txt"
  ask patches [file-write pxcor file-write pycor file-write patch-bite-count]
 file-print ""
 file-close

    file-open "PAC_2010.txt"
  ask patches [file-write pxcor file-write pycor file-write patch-agent-count]
 file-print ""
 file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
304
26
1163
281
-1
-1
1.0
1
10
1
1
1
0
1
1
1
0
850
-245
0
0
0
1
ticks
30.0

BUTTON
45
223
138
274
Setup
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
162
222
251
274
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
565
426
715
471
Number of bite (Per day)
count turtles with [bite-statu = \"True\"]
17
1
11

PLOT
305
290
559
470
Number of Tick-bite events per day
Days
Bite count
0.0
300.0
0.0
1000.0
false
false
"" ""
PENS
"Tick-bite (Per tick)" 1.0 0 -13791810 true "" "plot count turtles with [bite-statu = \"True\"]"

MONITOR
1006
425
1154
470
Total number of tick-bite
whole-bite-count
17
1
11

MONITOR
47
65
252
110
Temperature (0.1 degrees Celsius)
Temperature
17
1
11

MONITOR
47
126
199
171
Precipitation (0.1 mm)
Precipitation
17
1
11

TEXTBOX
49
33
199
51
Environment Variables :
14
0.0
1

PLOT
733
292
1000
471
Number of whole Tick-bite events
Days
Bite count
0.0
300.0
0.0
80000.0
false
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot whole-bite-count"

TEXTBOX
307
10
457
28
Schiermonnikoog :
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="EXP_Schier" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="360"/>
    <metric>whole-bite-count</metric>
  </experiment>
  <experiment name="Schier_2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>whole-bite-count</metric>
    <enumeratedValueSet variable="initial-number-residents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-tourists">
      <value value="0"/>
      <value value="200"/>
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
