; ModuleID = 'avx.bc'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define <8 x float> @shufps0(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 8, i32 8, i32 4, i32 4, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps1(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 8, i32 8, i32 5, i32 4, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps2(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 8, i32 8, i32 6, i32 4, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps3(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 8, i32 8, i32 7, i32 4, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps4(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 8, i32 8, i32 4, i32 5, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps5(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 8, i32 8, i32 5, i32 5, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps6(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 8, i32 8, i32 6, i32 5, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps7(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 8, i32 8, i32 7, i32 5, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps8(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 8, i32 8, i32 4, i32 6, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps9(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 8, i32 8, i32 5, i32 6, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps10(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 8, i32 8, i32 6, i32 6, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps11(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 8, i32 8, i32 7, i32 6, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps12(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 8, i32 8, i32 4, i32 7, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps13(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 8, i32 8, i32 5, i32 7, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps14(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 8, i32 8, i32 6, i32 7, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps15(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 8, i32 8, i32 7, i32 7, i32 12, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps16(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 9, i32 8, i32 4, i32 4, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps17(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 9, i32 8, i32 5, i32 4, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps18(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 9, i32 8, i32 6, i32 4, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps19(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 9, i32 8, i32 7, i32 4, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps20(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 9, i32 8, i32 4, i32 5, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps21(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 9, i32 8, i32 5, i32 5, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps22(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 9, i32 8, i32 6, i32 5, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps23(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 9, i32 8, i32 7, i32 5, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps24(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 9, i32 8, i32 4, i32 6, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps25(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 9, i32 8, i32 5, i32 6, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps26(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 9, i32 8, i32 6, i32 6, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps27(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 9, i32 8, i32 7, i32 6, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps28(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 9, i32 8, i32 4, i32 7, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps29(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 9, i32 8, i32 5, i32 7, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps30(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 9, i32 8, i32 6, i32 7, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps31(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 9, i32 8, i32 7, i32 7, i32 13, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps32(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 10, i32 8, i32 4, i32 4, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps33(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 10, i32 8, i32 5, i32 4, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps34(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 10, i32 8, i32 6, i32 4, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps35(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 10, i32 8, i32 7, i32 4, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps36(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 10, i32 8, i32 4, i32 5, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps37(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 10, i32 8, i32 5, i32 5, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps38(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 10, i32 8, i32 6, i32 5, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps39(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 10, i32 8, i32 7, i32 5, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps40(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 10, i32 8, i32 4, i32 6, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps41(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 10, i32 8, i32 5, i32 6, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps42(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 10, i32 8, i32 6, i32 6, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps43(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 10, i32 8, i32 7, i32 6, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps44(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 10, i32 8, i32 4, i32 7, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps45(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 10, i32 8, i32 5, i32 7, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps46(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 10, i32 8, i32 6, i32 7, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps47(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 10, i32 8, i32 7, i32 7, i32 14, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps48(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 11, i32 8, i32 4, i32 4, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps49(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 11, i32 8, i32 5, i32 4, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps50(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 11, i32 8, i32 6, i32 4, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps51(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 11, i32 8, i32 7, i32 4, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps52(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 11, i32 8, i32 4, i32 5, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps53(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 11, i32 8, i32 5, i32 5, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps54(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 11, i32 8, i32 6, i32 5, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps55(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 11, i32 8, i32 7, i32 5, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps56(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 11, i32 8, i32 4, i32 6, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps57(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 11, i32 8, i32 5, i32 6, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps58(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 11, i32 8, i32 6, i32 6, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps59(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 11, i32 8, i32 7, i32 6, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps60(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 11, i32 8, i32 4, i32 7, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps61(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 11, i32 8, i32 5, i32 7, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps62(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 11, i32 8, i32 6, i32 7, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps63(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 11, i32 8, i32 7, i32 7, i32 15, i32 12>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps64(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 8, i32 9, i32 4, i32 4, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps65(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 8, i32 9, i32 5, i32 4, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps66(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 8, i32 9, i32 6, i32 4, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps67(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 8, i32 9, i32 7, i32 4, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps68(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 8, i32 9, i32 4, i32 5, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps69(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 8, i32 9, i32 5, i32 5, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps70(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 8, i32 9, i32 6, i32 5, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps71(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 8, i32 9, i32 7, i32 5, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps72(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 8, i32 9, i32 4, i32 6, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps73(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 8, i32 9, i32 5, i32 6, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps74(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 8, i32 9, i32 6, i32 6, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps75(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 8, i32 9, i32 7, i32 6, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps76(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 8, i32 9, i32 4, i32 7, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps77(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 8, i32 9, i32 5, i32 7, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps78(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 8, i32 9, i32 6, i32 7, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps79(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 8, i32 9, i32 7, i32 7, i32 12, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps80(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 9, i32 9, i32 4, i32 4, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps81(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 9, i32 9, i32 5, i32 4, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps82(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 9, i32 9, i32 6, i32 4, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps83(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 9, i32 9, i32 7, i32 4, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps84(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 9, i32 9, i32 4, i32 5, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps85(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 9, i32 9, i32 5, i32 5, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps86(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 9, i32 9, i32 6, i32 5, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps87(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 9, i32 9, i32 7, i32 5, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps88(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 9, i32 9, i32 4, i32 6, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps89(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 9, i32 9, i32 5, i32 6, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps90(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 9, i32 9, i32 6, i32 6, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps91(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 9, i32 9, i32 7, i32 6, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps92(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 9, i32 9, i32 4, i32 7, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps93(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 9, i32 9, i32 5, i32 7, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps94(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 9, i32 9, i32 6, i32 7, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps95(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 9, i32 9, i32 7, i32 7, i32 13, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps96(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 10, i32 9, i32 4, i32 4, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps97(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 10, i32 9, i32 5, i32 4, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps98(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 10, i32 9, i32 6, i32 4, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps99(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 10, i32 9, i32 7, i32 4, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps100(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 10, i32 9, i32 4, i32 5, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps101(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 10, i32 9, i32 5, i32 5, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps102(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 10, i32 9, i32 6, i32 5, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps103(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 10, i32 9, i32 7, i32 5, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps104(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 10, i32 9, i32 4, i32 6, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps105(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 10, i32 9, i32 5, i32 6, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps106(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 10, i32 9, i32 6, i32 6, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps107(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 10, i32 9, i32 7, i32 6, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps108(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 10, i32 9, i32 4, i32 7, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps109(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 10, i32 9, i32 5, i32 7, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps110(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 10, i32 9, i32 6, i32 7, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps111(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 10, i32 9, i32 7, i32 7, i32 14, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps112(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 11, i32 9, i32 4, i32 4, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps113(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 11, i32 9, i32 5, i32 4, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps114(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 11, i32 9, i32 6, i32 4, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps115(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 11, i32 9, i32 7, i32 4, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps116(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 11, i32 9, i32 4, i32 5, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps117(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 11, i32 9, i32 5, i32 5, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps118(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 11, i32 9, i32 6, i32 5, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps119(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 11, i32 9, i32 7, i32 5, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps120(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 11, i32 9, i32 4, i32 6, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps121(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 11, i32 9, i32 5, i32 6, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps122(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 11, i32 9, i32 6, i32 6, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps123(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 11, i32 9, i32 7, i32 6, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps124(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 11, i32 9, i32 4, i32 7, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps125(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 11, i32 9, i32 5, i32 7, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps126(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 11, i32 9, i32 6, i32 7, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps127(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 11, i32 9, i32 7, i32 7, i32 15, i32 13>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps128(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 8, i32 10, i32 4, i32 4, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps129(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 8, i32 10, i32 5, i32 4, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps130(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 8, i32 10, i32 6, i32 4, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps131(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 8, i32 10, i32 7, i32 4, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps132(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 8, i32 10, i32 4, i32 5, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps133(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 8, i32 10, i32 5, i32 5, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps134(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 8, i32 10, i32 6, i32 5, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps135(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 8, i32 10, i32 7, i32 5, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps136(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 8, i32 10, i32 4, i32 6, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps137(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 8, i32 10, i32 5, i32 6, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps138(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 8, i32 10, i32 6, i32 6, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps139(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 8, i32 10, i32 7, i32 6, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps140(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 8, i32 10, i32 4, i32 7, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps141(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 8, i32 10, i32 5, i32 7, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps142(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 8, i32 10, i32 6, i32 7, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps143(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 8, i32 10, i32 7, i32 7, i32 12, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps144(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 9, i32 10, i32 4, i32 4, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps145(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 9, i32 10, i32 5, i32 4, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps146(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 9, i32 10, i32 6, i32 4, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps147(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 9, i32 10, i32 7, i32 4, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps148(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 9, i32 10, i32 4, i32 5, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps149(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 9, i32 10, i32 5, i32 5, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps150(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 9, i32 10, i32 6, i32 5, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps151(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 9, i32 10, i32 7, i32 5, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps152(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 9, i32 10, i32 4, i32 6, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps153(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 9, i32 10, i32 5, i32 6, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps154(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 9, i32 10, i32 6, i32 6, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps155(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 9, i32 10, i32 7, i32 6, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps156(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 9, i32 10, i32 4, i32 7, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps157(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 9, i32 10, i32 5, i32 7, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps158(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 9, i32 10, i32 6, i32 7, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps159(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 9, i32 10, i32 7, i32 7, i32 13, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps160(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 10, i32 10, i32 4, i32 4, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps161(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 10, i32 10, i32 5, i32 4, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps162(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 10, i32 10, i32 6, i32 4, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps163(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 10, i32 10, i32 7, i32 4, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps164(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 10, i32 10, i32 4, i32 5, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps165(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 10, i32 10, i32 5, i32 5, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps166(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 10, i32 10, i32 6, i32 5, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps167(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 10, i32 10, i32 7, i32 5, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps168(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 10, i32 10, i32 4, i32 6, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps169(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 10, i32 10, i32 5, i32 6, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps170(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 10, i32 10, i32 6, i32 6, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps171(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 10, i32 10, i32 7, i32 6, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps172(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 10, i32 10, i32 4, i32 7, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps173(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 10, i32 10, i32 5, i32 7, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps174(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 10, i32 10, i32 6, i32 7, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps175(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 10, i32 10, i32 7, i32 7, i32 14, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps176(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 11, i32 10, i32 4, i32 4, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps177(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 11, i32 10, i32 5, i32 4, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps178(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 11, i32 10, i32 6, i32 4, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps179(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 11, i32 10, i32 7, i32 4, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps180(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 11, i32 10, i32 4, i32 5, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps181(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 11, i32 10, i32 5, i32 5, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps182(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 11, i32 10, i32 6, i32 5, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps183(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 11, i32 10, i32 7, i32 5, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps184(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 11, i32 10, i32 4, i32 6, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps185(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 11, i32 10, i32 5, i32 6, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps186(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 11, i32 10, i32 6, i32 6, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps187(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 11, i32 10, i32 7, i32 6, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps188(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 11, i32 10, i32 4, i32 7, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps189(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 11, i32 10, i32 5, i32 7, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps190(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 11, i32 10, i32 6, i32 7, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps191(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 11, i32 10, i32 7, i32 7, i32 15, i32 14>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps192(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 8, i32 11, i32 4, i32 4, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps193(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 8, i32 11, i32 5, i32 4, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps194(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 8, i32 11, i32 6, i32 4, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps195(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 8, i32 11, i32 7, i32 4, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps196(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 8, i32 11, i32 4, i32 5, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps197(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 8, i32 11, i32 5, i32 5, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps198(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 8, i32 11, i32 6, i32 5, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps199(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 8, i32 11, i32 7, i32 5, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps200(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 8, i32 11, i32 4, i32 6, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps201(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 8, i32 11, i32 5, i32 6, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps202(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 8, i32 11, i32 6, i32 6, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps203(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 8, i32 11, i32 7, i32 6, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps204(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 8, i32 11, i32 4, i32 7, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps205(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 8, i32 11, i32 5, i32 7, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps206(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 8, i32 11, i32 6, i32 7, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps207(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 8, i32 11, i32 7, i32 7, i32 12, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps208(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 9, i32 11, i32 4, i32 4, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps209(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 9, i32 11, i32 5, i32 4, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps210(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 9, i32 11, i32 6, i32 4, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps211(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 9, i32 11, i32 7, i32 4, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps212(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 9, i32 11, i32 4, i32 5, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps213(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 9, i32 11, i32 5, i32 5, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps214(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 9, i32 11, i32 6, i32 5, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps215(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 9, i32 11, i32 7, i32 5, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps216(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 9, i32 11, i32 4, i32 6, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps217(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 9, i32 11, i32 5, i32 6, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps218(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 9, i32 11, i32 6, i32 6, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps219(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 9, i32 11, i32 7, i32 6, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps220(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 9, i32 11, i32 4, i32 7, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps221(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 9, i32 11, i32 5, i32 7, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps222(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 9, i32 11, i32 6, i32 7, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps223(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 9, i32 11, i32 7, i32 7, i32 13, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps224(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 10, i32 11, i32 4, i32 4, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps225(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 10, i32 11, i32 5, i32 4, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps226(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 10, i32 11, i32 6, i32 4, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps227(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 10, i32 11, i32 7, i32 4, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps228(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 10, i32 11, i32 4, i32 5, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps229(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 10, i32 11, i32 5, i32 5, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps230(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 10, i32 11, i32 6, i32 5, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps231(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 10, i32 11, i32 7, i32 5, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps232(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 10, i32 11, i32 4, i32 6, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps233(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 10, i32 11, i32 5, i32 6, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps234(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 10, i32 11, i32 6, i32 6, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps235(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 10, i32 11, i32 7, i32 6, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps236(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 10, i32 11, i32 4, i32 7, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps237(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 10, i32 11, i32 5, i32 7, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps238(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 10, i32 11, i32 6, i32 7, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps239(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 10, i32 11, i32 7, i32 7, i32 14, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps240(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 0, i32 11, i32 11, i32 4, i32 4, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps241(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 0, i32 11, i32 11, i32 5, i32 4, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps242(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 0, i32 11, i32 11, i32 6, i32 4, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps243(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 0, i32 11, i32 11, i32 7, i32 4, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps244(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 1, i32 11, i32 11, i32 4, i32 5, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps245(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 1, i32 11, i32 11, i32 5, i32 5, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps246(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 1, i32 11, i32 11, i32 6, i32 5, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps247(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 1, i32 11, i32 11, i32 7, i32 5, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps248(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 2, i32 11, i32 11, i32 4, i32 6, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps249(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 2, i32 11, i32 11, i32 5, i32 6, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps250(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 2, i32 11, i32 11, i32 6, i32 6, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps251(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 2, i32 11, i32 11, i32 7, i32 6, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps252(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 3, i32 11, i32 11, i32 4, i32 7, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps253(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 1, i32 3, i32 11, i32 11, i32 5, i32 7, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps254(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 3, i32 11, i32 11, i32 6, i32 7, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @shufps255(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 3, i32 3, i32 11, i32 11, i32 7, i32 7, i32 15, i32 15>
  ret <8 x float> %shuffle
}

define <8 x float> @insert128_0(<8 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %0 = tail call <8 x float> @llvm.x86.avx.vinsertf128.ps.256(<8 x float> %a, <4 x float> %b, i8 0) nounwind
  ret <8 x float> %0
}

define <8 x float> @insert128_1(<8 x float> %a, <4 x float> %b) nounwind uwtable readnone {
entry:
  %0 = tail call <8 x float> @llvm.x86.avx.vinsertf128.ps.256(<8 x float> %a, <4 x float> %b, i8 1) nounwind
  ret <8 x float> %0
}

define <4 x float> @extract128_0(<8 x float> %a) nounwind uwtable readnone {
entry:
  %0 = tail call <4 x float> @llvm.x86.avx.vextractf128.ps.256(<8 x float> %a, i8 0) nounwind
  ret <4 x float> %0
}

define <4 x float> @extract128_1(<8 x float> %a) nounwind uwtable readnone {
entry:
  %0 = tail call <4 x float> @llvm.x86.avx.vextractf128.ps.256(<8 x float> %a, i8 1) nounwind
  ret <4 x float> %0
}

define <8 x float> @interleave128_lo(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %0 = tail call <8 x float> @llvm.x86.avx.vperm2f128.ps.256(<8 x float> %a, <8 x float> %b, i8 32) nounwind
  ret <8 x float> %0
}

define <8 x float> @interleave128_hi(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %0 = tail call <8 x float> @llvm.x86.avx.vperm2f128.ps.256(<8 x float> %a, <8 x float> %b, i8 49) nounwind
  ret <8 x float> %0
}

define <8 x float> @broadcast128(<4 x float>* %p) nounwind uwtable readonly {
entry:
  %0 = bitcast <4 x float>* %p to i8*
  %1 = tail call <8 x float> @llvm.x86.avx.vbroadcastf128.ps.256(i8* %0) nounwind
  ret <8 x float> %1
}

define <8 x float> @unpckhps(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle.i = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 2, i32 10, i32 3, i32 11, i32 6, i32 14, i32 7, i32 15>
  ret <8 x float> %shuffle.i
}

define <8 x float> @unpcklps(<8 x float> %a, <8 x float> %b) nounwind uwtable readnone {
entry:
  %shuffle.i = shufflevector <8 x float> %a, <8 x float> %b, <8 x i32> <i32 0, i32 8, i32 1, i32 9, i32 4, i32 12, i32 5, i32 13>
  ret <8 x float> %shuffle.i
}

declare <8 x float> @llvm.x86.avx.vbroadcastf128.ps.256(i8*) nounwind readonly

declare <8 x float> @llvm.x86.avx.vperm2f128.ps.256(<8 x float>, <8 x float>, i8) nounwind readnone

declare <4 x float> @llvm.x86.avx.vextractf128.ps.256(<8 x float>, i8) nounwind readnone

declare <8 x float> @llvm.x86.avx.vinsertf128.ps.256(<8 x float>, <4 x float>, i8) nounwind readnone
