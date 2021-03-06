//
//  Defined.swift
//  project6
//
//  Created by Tushit Jain on 4/14/17.
//  Copyright © 2017 Tushit Jain. All rights reserved.
//

import Foundation
import CoreGraphics

let DefinedScreenWidth:CGFloat = 1536
let DefinedScreenHeight:CGFloat = 2048

enum StickHeroGameSceneChildName : String {
    case HeroName = "hero"
    case StickName = "stick"
    case StackName = "stack"
    case StackMidName = "stack_mid"
    case ScoreName = "score"
    case TipName = "tip"
    case PerfectName = "perfect"
    case GameOverLayerName = "over"
    case RetryButtonName = "retry"
    case HighScoreName = "highscore"
    case LifeLeft = "lifeleft"
}

enum StickHeroGameSceneActionKey: String {
    case WalkAction = "walk"
    case StickGrowAudioAction = "stick_grow_audio"
    case StickGrowAction = "stick_grow"
    case HeroScaleAction = "hero_scale"
}

enum StickHeroGameSceneEffectAudioName: String {
    case DeadAudioName = "dead.wav"
    case StickGrowAudioName = "stick_grow_loop.wav"
    case StickGrowOverAudioName = "kick.wav"
    case StickFallAudioName = "fall.wav"
    case StickTouchMidAudioName = "touch_mid.wav"
    case VictoryAudioName = "victory.wav"
    case HighScoreAudioName = "highScore.wav"
}

enum StickHeroGameSceneZposition: CGFloat {
    case backgroundZposition = 0
    case stackZposition = 30
    case stackMidZposition = 35
    case stickZposition = 40
    case scoreBackgroundZposition = 50
    case heroZposition, scoreZposition, tipZposition, lifeLeft, perfectZposition = 100
    case emitterZposition
    case gameOverZposition
}
