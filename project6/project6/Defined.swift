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
}

enum StickHeroGameSceneActionKey: String {
    case WalkAction = "walk"
    case StickGrowAudioAction = "stick_grow_audio"
    case StickGrowAction = "stick_grow"
    case HeroScaleAction = "hero_scale"
}
