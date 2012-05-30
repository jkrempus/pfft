; ModuleID = '<stdin>'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define <4 x float> @shufps0(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps1(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps2(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps3(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps4(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps5(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps6(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps7(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps8(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps9(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps10(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps11(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps12(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps13(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps14(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps15(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 4, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps16(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps17(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps18(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps19(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps20(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps21(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps22(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps23(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps24(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps25(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps26(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps27(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps28(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps29(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps30(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps31(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 5, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps32(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps33(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps34(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps35(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps36(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps37(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps38(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps39(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps40(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps41(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps42(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps43(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps44(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps45(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps46(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps47(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 6, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps48(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps49(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps50(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps51(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps52(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps53(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps54(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps55(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps56(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps57(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps58(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps59(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps60(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps61(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps62(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps63(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 7, i32 4>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps64(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps65(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps66(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps67(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps68(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps69(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps70(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps71(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps72(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps73(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps74(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps75(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps76(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps77(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps78(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps79(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 4, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps80(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps81(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps82(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps83(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps84(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps85(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps86(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps87(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps88(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps89(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps90(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps91(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps92(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps93(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps94(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps95(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 5, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps96(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps97(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps98(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps99(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps100(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps101(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps102(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps103(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps104(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps105(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps106(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps107(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps108(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps109(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps110(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps111(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 6, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps112(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps113(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps114(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps115(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps116(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps117(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps118(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps119(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps120(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps121(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps122(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps123(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps124(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps125(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps126(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps127(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 7, i32 5>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps128(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps129(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps130(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps131(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps132(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps133(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps134(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps135(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps136(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps137(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps138(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps139(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps140(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps141(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps142(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps143(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 4, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps144(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps145(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps146(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps147(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps148(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps149(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps150(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps151(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps152(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps153(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps154(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps155(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps156(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps157(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps158(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps159(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 5, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps160(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps161(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps162(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps163(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps164(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps165(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps166(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps167(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps168(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps169(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps170(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps171(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps172(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps173(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps174(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps175(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 6, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps176(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps177(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps178(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps179(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps180(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps181(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps182(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps183(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps184(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps185(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps186(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps187(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps188(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps189(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps190(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps191(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 7, i32 6>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps192(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps193(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps194(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps195(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps196(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps197(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps198(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps199(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps200(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps201(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps202(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps203(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps204(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps205(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps206(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps207(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 4, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps208(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps209(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps210(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps211(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps212(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps213(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps214(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps215(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps216(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps217(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps218(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps219(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps220(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps221(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps222(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps223(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 5, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps224(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps225(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps226(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps227(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps228(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps229(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps230(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps231(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps232(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps233(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps234(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps235(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps236(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps237(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps238(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps239(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 6, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps240(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 0, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps241(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 0, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps242(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 0, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps243(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 0, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps244(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 1, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps245(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps246(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 1, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps247(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 1, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps248(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 2, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps249(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 2, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps250(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 2, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps251(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 2, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps252(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 3, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps253(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 1, i32 3, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps254(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 2, i32 3, i32 7, i32 7>
  ret <4 x float> %shuffle
}

define <4 x float> @shufps255(<4 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 3, i32 3, i32 7, i32 7>
  ret <4 x float> %shuffle
}
