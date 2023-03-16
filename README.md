# TitalyverG

TimeTagedLyricsViewer Godot Version

動画
https://twitter.com/Juna_idler/status/1623803736752812032?s=20

## 概要
Godotの機能を見てたらなんか移植できそうだったのでhttps://github.com/Juna-Idler/Titalyver2

処理速度は、WPFで何も考えずに組んでだ2の描画のクソ重さに比べたら圧倒的に速い。とにかくそうそうコマ落ちしない。
ただし処理内容に対するCPU使用量が適正かどうかは知らん。


## 問題点

- Finderが同期処理なのでネット上から探すときとかめっちゃブロックする。
- カラオケワイプを文字単位の色変化で表現しているが、普通のくっきり縦割りタイプが現状の手法ではできないっぽい。
- Shift-jisは捨てた

