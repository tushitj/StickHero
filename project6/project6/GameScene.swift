//
//  GameScene.swift
//  project6
//
//  Created by Tushit Jain on 4/7/17.
//  Copyright © 2017 Tushit Jain. All rights reserved.
//
import SpriteKit
import GameplayKit
class GameScene: SKScene, SKPhysicsContactDelegate  {
    let StackHeight:CGFloat = 400.0
    let StackMaxWidth:CGFloat = 300.0
    let StackMinWidth:CGFloat = 100.0
    let gravity:CGFloat = -100.0
    let StackGapMinWidth:Int = 80
    let HeroSpeed:CGFloat = 760
    let StoreScoreName = "com.stickHero.score"
    var isBegin = false
    var isEnd = false
    var leftStack:SKSpriteNode?
    var rightStack:SKSpriteNode?
    var playerlife : SKSpriteNode = SKSpriteNode()
    var lifeLabel : SKLabelNode = SKLabelNode()
    var nextLeftStartX:CGFloat = 0
    var stickHeight:CGFloat = 0
    struct GAP {
        static let XGAP:CGFloat = 20
        static let YGAP:CGFloat = 4
    }
    var gameOver = false {
        willSet {
            if (newValue) {
                checkHighScoreAndStore()
                let gameOverLayer = childNode(withName: StickHeroGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
                gameOverLayer?.run(SKAction.moveDistance(CGVector(dx: 0, dy: 100), fadeInWithDuration: 0.2))
            }
        }
    }
    override func didMove(to view: SKView) {
        start()
    }
    func touchDown(atPoint pos : CGPoint) {
    }
    func touchMoved(toPoint pos : CGPoint) {
    }
    func touchUp(atPoint pos : CGPoint) {
    }
    var score:Int = 0 {
        willSet {
            let scoreBand = childNode(withName: StickHeroGameSceneChildName.ScoreName.rawValue) as? SKLabelNode
            scoreBand?.text = "\(newValue)"
            scoreBand?.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))
            if (newValue == 1) {
                let tip = childNode(withName: StickHeroGameSceneChildName.TipName.rawValue) as? SKLabelNode
                tip?.run(SKAction.fadeAlpha(to: 0, duration: 0.4))
            }
        }
    }
    lazy var playAbleRect:CGRect = {
        let maxAspectRatio:CGFloat = 16.0/9.0 // iPhone 5"
        let maxAspectRatioWidth = self.size.height / maxAspectRatio
        let playableMargin = (self.size.width - maxAspectRatioWidth) / 2.0
        return CGRect(x: playableMargin, y: 0, width: maxAspectRatioWidth, height: self.size.height)
    }()
    lazy var walkAction:SKAction = {
        var textures:[SKTexture] = []
        for i in 0...3 {
            let texture = SKTexture(imageNamed: "player\(i + 1).png")
            textures.append(texture)
        }
        let action = SKAction.animate(with: textures, timePerFrame: 0.15, resize: true, restore: true)
        return SKAction.repeatForever(action)
    }()
    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.contactDelegate = self
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver else {
            let gameOverLayer = childNode(withName: StickHeroGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
            let location = touches.first?.location(in: gameOverLayer!)
            let retry = gameOverLayer!.atPoint(location!)
            if (retry.name == StickHeroGameSceneChildName.RetryButtonName.rawValue) {
                retry.run(SKAction.sequence([SKAction.setTexture(SKTexture(imageNamed: "button_retry_down"), resize: false), SKAction.wait(forDuration: 0.3)]), completion: {[unowned self] () -> Void in
                    self.restart()
                })
            }
            return
        }
        if !isBegin && !isEnd {
            isBegin = true
            let stick = loadStick()
            let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
            let action = SKAction.resize(toHeight: CGFloat(DefinedScreenHeight - StackHeight), duration: 1.5)
            stick.run(action, withKey:StickHeroGameSceneActionKey.StickGrowAction.rawValue)
            let scaleAction = SKAction.sequence([SKAction.scaleY(to: 0.9, duration: 0.05), SKAction.scaleY(to: 1, duration: 0.05)])
            let loopAction = SKAction.group([SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickGrowAudioName.rawValue, waitForCompletion: true)])
            stick.run(SKAction.repeatForever(loopAction), withKey: StickHeroGameSceneActionKey.StickGrowAudioAction.rawValue)
            hero.run(SKAction.repeatForever(scaleAction), withKey: StickHeroGameSceneActionKey.HeroScaleAction.rawValue)
            return
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isBegin && !isEnd {
            isEnd  = true
            let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
            hero.removeAction(forKey: StickHeroGameSceneActionKey.HeroScaleAction.rawValue)
            hero.run(SKAction.scaleY(to: 1, duration: 0.04))
            let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
            stick.removeAction(forKey: StickHeroGameSceneActionKey.StickGrowAction.rawValue)
            stick.removeAction(forKey: StickHeroGameSceneActionKey.StickGrowAudioAction.rawValue)
            stick.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickGrowOverAudioName.rawValue, waitForCompletion: false))
            stickHeight = stick.size.height;
            let action = SKAction.rotate(toAngle: CGFloat(-CGFloat.pi / 2), duration: 0.4, shortestUnitArc: true)
            let playFall = SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickFallAudioName.rawValue, waitForCompletion: false)
            stick.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), action, playFall]), completion: {[unowned self] () -> Void in
                self.heroGo(self.checkPass())
            })
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    func start() {
        loadBackground()
        loadScoreBackground()
        loadScore()
        loadTip()
        loadGameOverLayer()
        leftStack = loadStacks(false, startLeftPoint: playAbleRect.origin.x)
        self.removeMidTouch(false, left:true)
        loadHero()
        let maxGap = Int(playAbleRect.width - StackMaxWidth - (leftStack?.frame.size.width)!)
        let gap = CGFloat(randomInRange(StackGapMinWidth...maxGap))
        rightStack = loadStacks(false, startLeftPoint: nextLeftStartX + gap)
        gameOver = false
    }
    func restart() {
        isBegin = false
        isEnd = false
        score = 0
        nextLeftStartX = 0
        removeAllChildren()
        start()
    }
    fileprivate func checkPass() -> Bool {
        let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        let rightPoint = DefinedScreenWidth / 2 + stick.position.x + self.stickHeight
        guard rightPoint < self.nextLeftStartX else {
            if reducelife(){
                return true
            }
            return false
        }
        guard ((leftStack?.frame)!.intersects(stick.frame) && (rightStack?.frame)!.intersects(stick.frame)) else {
            if reducelife(){
                return true
            }
            return false
        }
        self.checkTouchMidStack()
        return true
    }
    fileprivate func checkTouchMidStack() {
        let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        let stackMid = rightStack!.childNode(withName: StickHeroGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        let newPoint = stackMid.convert(CGPoint(x: -10, y: 10), to: self)
        if ((stick.position.x + self.stickHeight) >= newPoint.x  && (stick.position.x + self.stickHeight) <= newPoint.x + 20) {
            loadPerfect()
            self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickTouchMidAudioName.rawValue, waitForCompletion: false))
            score += 1
        }
    }
    fileprivate func heroGo(_ pass:Bool) {
        let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        guard pass else {
            let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
            let dis:CGFloat = stick.position.x + self.stickHeight
            let overGap = DefinedScreenWidth / 2 - abs(hero.position.x)
            let disGap = nextLeftStartX - overGap - (rightStack?.frame.size.width)! / 2
            let move = SKAction.moveTo(x: dis, duration: TimeInterval(abs(disGap / HeroSpeed)))
            hero.run(walkAction, withKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
            hero.run(move, completion: {[unowned self] () -> Void in
                stick.run(SKAction.rotate(toAngle: CGFloat(-CGFloat.pi), duration: 0.4))
                hero.physicsBody!.affectedByGravity = true
                hero.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.DeadAudioName.rawValue, waitForCompletion: false))
                hero.removeAction(forKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
                self.run(SKAction.wait(forDuration: 0.5), completion: {[unowned self] () -> Void in
                    self.gameOver = true
                })
            })
            return
        }
        let dis:CGFloat = nextLeftStartX - DefinedScreenWidth / 2 - hero.size.width / 2 - GAP.XGAP
        let overGap = DefinedScreenWidth / 2 - abs(hero.position.x)
        let disGap = nextLeftStartX - overGap - (rightStack?.frame.size.width)! / 2
        let move = SKAction.moveTo(x: dis, duration: TimeInterval(abs(disGap / HeroSpeed)))
        hero.run(walkAction, withKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
        hero.run(move, completion: { [unowned self]() -> Void in
            self.score += 1
            hero.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.VictoryAudioName.rawValue, waitForCompletion: false))
            hero.removeAction(forKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
            self.moveStackAndCreateNew()
        })
    }
    fileprivate func removeMidTouch(_ animate:Bool, left:Bool) {
        let stack = left ? leftStack : rightStack
        let mid = stack!.childNode(withName: StickHeroGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        if (animate) {
            mid.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
        }
        else {
            mid.removeFromParent()
        }
    }
    fileprivate func checkHighScoreAndStore() {
        let highScore = UserDefaults.standard.integer(forKey: StoreScoreName)
        if (score > Int(highScore)) {
            showHighScore()
            UserDefaults.standard.set(score, forKey: StoreScoreName)
            UserDefaults.standard.synchronize()
        }
    }
    fileprivate func showHighScore() {
        self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.HighScoreAudioName.rawValue, waitForCompletion: false))
        let wait = SKAction.wait(forDuration: 0.4)
        let grow = SKAction.scale(to: 1.5, duration: 0.4)
        grow.timingMode = .easeInEaseOut
        let explosion = starEmitterActionAtPosition(CGPoint(x: 0, y: 300))
        let shrink = SKAction.scale(to: 1, duration: 0.2)
        let idleGrow = SKAction.scale(to: 1.2, duration: 0.4)
        idleGrow.timingMode = .easeInEaseOut
        let idleShrink = SKAction.scale(to: 1, duration: 0.4)
        let pulsate = SKAction.repeatForever(SKAction.sequence([idleGrow, idleShrink]))
        let gameOverLayer = childNode(withName: StickHeroGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
        let highScoreLabel = gameOverLayer?.childNode(withName: StickHeroGameSceneChildName.HighScoreName.rawValue) as SKNode?
        highScoreLabel?.run(SKAction.sequence([wait, explosion, grow, shrink]), completion: { () -> Void in
            highScoreLabel?.run(pulsate)
        })
    }
    fileprivate func moveStackAndCreateNew() {
        let action = SKAction.move(by: CGVector(dx: -nextLeftStartX + (rightStack?.frame.size.width)! + playAbleRect.origin.x - 2, dy: 0), duration: 0.3)
        rightStack?.run(action)
        self.removeMidTouch(true, left:false)
        let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        hero.run(action)
        stick.run(SKAction.group([SKAction.move(by: CGVector(dx: -DefinedScreenWidth, dy: 0), duration: 0.5), SKAction.fadeAlpha(to: 0, duration: 0.3)]), completion: { () -> Void in
            stick.removeFromParent()
        })
        leftStack?.run(SKAction.move(by: CGVector(dx: -DefinedScreenWidth, dy: 0), duration: 0.5), completion: {[unowned self] () -> Void in
            self.leftStack?.removeFromParent()
            let maxGap = Int(self.playAbleRect.width - (self.rightStack?.frame.size.width)! - self.StackMaxWidth)
            let gap = CGFloat(randomInRange(self.StackGapMinWidth...maxGap))
            self.leftStack = self.rightStack
            self.rightStack = self.loadStacks(true, startLeftPoint:self.playAbleRect.origin.x + (self.rightStack?.frame.size.width)! + gap)
        })
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//MARK: - load node
private extension GameScene {
    func loadBackground() {
        //scene.size = skView.bounds.size
        guard let _ = childNode(withName: "background") as! SKSpriteNode? else {
            let texture = SKTexture(image: UIImage(named: "backImage1.jpg")!)
            let node = SKSpriteNode(texture: texture)
            node.size = self.size//texture.size()
            node.zPosition = StickHeroGameSceneZposition.backgroundZposition.rawValue
            self.physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
            addChild(node)
            return
        }
    }
    func reducelife() -> Bool{
        let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        hero.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.DeadAudioName.rawValue, waitForCompletion: false))
        var lifeLeft = hero.userData?["life"]! as! Int
        if lifeLeft > 0
        {
            lifeLeft -= 1
            hero.userData?.setValue(lifeLeft, forKey: "life")
            lifeLabel.text = "x "+String(lifeLeft)
            let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            label.name = StickHeroGameSceneChildName.TipName.rawValue
            label.text = "life -1"
            label.position = CGPoint(x: 0, y: DefinedScreenHeight / 2 - 550)
            label.fontColor = SKColor.black
            label.fontSize = 65
            label.zPosition = StickHeroGameSceneZposition.tipZposition.rawValue
            label.horizontalAlignmentMode = .center
            addChild(label)
            let waitAction = SKAction.wait(forDuration: 1.2)
            let removeAction = SKAction.removeFromParent()
            label.run(SKAction.sequence([waitAction,removeAction]))
            return true
        }
        return false
    }
    func loadScore() {
        let scoreBand = SKLabelNode(fontNamed: "Arial")
        scoreBand.name = StickHeroGameSceneChildName.ScoreName.rawValue
        scoreBand.text = "0"
        scoreBand.position = CGPoint(x: 0, y: DefinedScreenHeight / 2 - 200)
        scoreBand.fontColor = SKColor.white
        scoreBand.fontSize = 100
        scoreBand.zPosition = StickHeroGameSceneZposition.scoreZposition.rawValue
        scoreBand.horizontalAlignmentMode = .center
        addChild(scoreBand)
    }
    func loadScoreBackground() {
        let back = SKShapeNode(rect: CGRect(x: 0-120, y: 1024-200-30, width: 240, height: 140), cornerRadius: 20)
        back.zPosition = StickHeroGameSceneZposition.scoreBackgroundZposition.rawValue
        back.fillColor = SKColor.black.withAlphaComponent(0.3)
        back.strokeColor = SKColor.black.withAlphaComponent(0.3)
        addChild(back)
    }
    func loadHero() {
        let hero = SKSpriteNode(imageNamed: "player1")
        hero.name = StickHeroGameSceneChildName.HeroName.rawValue
        let x:CGFloat = nextLeftStartX - DefinedScreenWidth / 2 - hero.size.width / 2 - GAP.XGAP
        let y:CGFloat = StackHeight + hero.size.height / 2 - DefinedScreenHeight / 2 - GAP.YGAP
        hero.position = CGPoint(x: x, y: y)
        hero.zPosition = StickHeroGameSceneZposition.heroZposition.rawValue
        hero.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 18))
        hero.physicsBody?.affectedByGravity = false
        hero.physicsBody?.allowsRotation = false
        hero.userData = NSMutableDictionary()
        hero.userData?.setValue(3, forKey: "life")
        addChild(hero)
        loadLife()
    }
    func loadTip() {
        let tip = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        tip.name = StickHeroGameSceneChildName.TipName.rawValue
        tip.text = "The Game"
        tip.position = CGPoint(x: 0, y: DefinedScreenHeight / 2 - 350)
        tip.fontColor = SKColor.black
        tip.fontSize = 52
        tip.zPosition = StickHeroGameSceneZposition.tipZposition.rawValue
        tip.horizontalAlignmentMode = .center
        addChild(tip)
    }
    func loadPerfect() {
        defer {
            let perfect = childNode(withName: StickHeroGameSceneChildName.PerfectName.rawValue) as! SKLabelNode?
            let sequence = SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.3), SKAction.fadeAlpha(to: 0, duration: 0.3)])
            let scale = SKAction.sequence([SKAction.scale(to: 1.4, duration: 0.3), SKAction.scale(to: 1, duration: 0.3)])
            perfect!.run(SKAction.group([sequence, scale]))
        }
        guard let _ = childNode(withName: StickHeroGameSceneChildName.PerfectName.rawValue) as! SKLabelNode? else {
            let perfect = SKLabelNode(fontNamed: "Arial")
            perfect.text = "Perfect +1 Life +1"
            perfect.name = StickHeroGameSceneChildName.PerfectName.rawValue
            perfect.position = CGPoint(x: 0, y: -100)
            perfect.fontColor = SKColor.black
            perfect.fontSize = 50
            perfect.zPosition = StickHeroGameSceneZposition.perfectZposition.rawValue
            perfect.horizontalAlignmentMode = .center
            perfect.alpha = 0
            let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
            var lifeLeft:Int = hero.userData?["life"]! as! Int
            lifeLeft += 1
            hero.userData?.setValue(lifeLeft, forKey: "life")
            lifeLabel.text = "x "+String(lifeLeft)
            addChild(perfect)
            return
        }
    }
    func loadStick() -> SKSpriteNode {
        let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        let stick = SKSpriteNode(color: .brown, size: CGSize(width: 12, height: 1))
        stick.zPosition = StickHeroGameSceneZposition.stickZposition.rawValue
        stick.name = StickHeroGameSceneChildName.StickName.rawValue
        stick.anchorPoint = CGPoint(x: 0.5, y: 0);
        stick.position = CGPoint(x: hero.position.x + hero.size.width / 2 + 18, y: hero.position.y - hero.size.height / 2)
        addChild(stick)
        return stick
    }
    //platform
    func loadStacks(_ animate: Bool, startLeftPoint: CGFloat) -> SKSpriteNode {
        let max:Int = Int(StackMaxWidth / 10)
        let min:Int = Int(StackMinWidth / 10)
        let width:CGFloat = CGFloat(randomInRange(min...max) * 10)
        let height:CGFloat = StackHeight
        //let stack = SKShapeNode(rectOf: CGSize(width: width, height: height))
        let stack = SKSpriteNode(imageNamed: "stack1.png")
        stack.size = CGSize(width: width, height: height)
        // stack.fillColor = .black
        // stack.strokeColor = .black
        stack.zPosition = StickHeroGameSceneZposition.stackZposition.rawValue
        stack.name = StickHeroGameSceneChildName.StackName.rawValue
        if (animate) {
            stack.position = CGPoint(x: DefinedScreenWidth / 2, y: -DefinedScreenHeight / 2 + height / 2)
            stack.run(SKAction.moveTo(x: -DefinedScreenWidth / 2 + width / 2 + startLeftPoint, duration: 0.3), completion: {[unowned self] () -> Void in
                self.isBegin = false
                self.isEnd = false
            })
        }
        else {
            stack.position = CGPoint(x: -DefinedScreenWidth / 2 + width / 2 + startLeftPoint, y: -DefinedScreenHeight / 2 + height / 2)
        }
        addChild(stack)
        let mid = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
        mid.fillColor = SKColor.green
        mid.strokeColor = SKColor.green
        mid.zPosition = StickHeroGameSceneZposition.stackMidZposition.rawValue
        mid.name = StickHeroGameSceneChildName.StackMidName.rawValue
        //mid.position = CGPoint(x: 0, y: height / 2 - 20 / 2)
        mid.position = CGPoint(x: 0, y: height / 2 - 20 / 2)
        stack.addChild(mid)
        nextLeftStartX = width + startLeftPoint
        return stack
    }
    func loadLife(){
        let playerlife = SKSpriteNode(imageNamed: "player1")
        playerlife.name = StickHeroGameSceneChildName.LifeLeft.rawValue
        //tip.text = "The Game"
        let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        let lifeLeft:String = String(hero.userData?["life"]! as! Int)
        playerlife.position = CGPoint(x: -50, y: DefinedScreenHeight / 2 - 400)
        playerlife.zPosition = StickHeroGameSceneZposition.lifeLeft.rawValue
        //tip.horizontalAlignmentMode = .center
        lifeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        lifeLabel.text = "x "+lifeLeft
        lifeLabel.fontColor = .black
        lifeLabel.fontSize = 60
        lifeLabel.position =  CGPoint(x: 100, y: -20)
        lifeLabel.horizontalAlignmentMode = .center
        playerlife.addChild(lifeLabel)
        addChild(playerlife)
    }
    func loadGameOverLayer() {
        let node = SKNode()
        node.alpha = 0
        node.name = StickHeroGameSceneChildName.GameOverLayerName.rawValue
        node.zPosition = StickHeroGameSceneZposition.gameOverZposition.rawValue
        addChild(node)
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = "Game Over"
        label.fontColor = SKColor.red
        label.fontSize = 150
        label.position = CGPoint(x: 0, y: 100)
        label.horizontalAlignmentMode = .center
        node.addChild(label)
        let retry = SKSpriteNode(imageNamed: "button_retry_up")
        retry.name = StickHeroGameSceneChildName.RetryButtonName.rawValue
        retry.position = CGPoint(x: 0, y: -200)
        node.addChild(retry)
        let highScore = SKLabelNode(fontNamed: "AmericanTypewriter")
        highScore.text = "Highscore!"
        highScore.fontColor = UIColor.white
        highScore.fontSize = 50
        highScore.name = StickHeroGameSceneChildName.HighScoreName.rawValue
        highScore.position = CGPoint(x: 0, y: 300)
        highScore.horizontalAlignmentMode = .center
        highScore.setScale(0)
        node.addChild(highScore)
    }
    //MARK: - Action
    func starEmitterActionAtPosition(_ position: CGPoint) -> SKAction {
        let emitter = SKEmitterNode(fileNamed: "StarExplosion")
        emitter?.position = position
        emitter?.zPosition = StickHeroGameSceneZposition.emitterZposition.rawValue
        emitter?.alpha = 0.6
        addChild((emitter)!)
        let wait = SKAction.wait(forDuration: 0.15)
        return SKAction.run({ () -> Void in
            emitter?.run(wait)
        })
    }
}
