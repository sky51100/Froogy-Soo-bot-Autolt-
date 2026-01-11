#cs
    BDS Farm Bot
    =====================
    Automatisation du farm Soo (BDS)
    Auteur : Sky
#ce

#RequireAdmin
#include "C:\Users\yoann\Desktop\GW & co\2025\GwAu3-main\API\_GwAu3.au3"
#include "C:\Users\yoann\Desktop\GW & co\2025\GwAu3-main\Scripts\AddOns\GwAu3_AddOns_BDS.au3"

; ========================================
; Summoning Stone Timer + Anti-Sickness
; ========================================
Global $g_LastSummonTime = TimerInit()

Func _CheckSummoningTimer()
    ; Vérifie toutes les 10 minutes
    If TimerDiff($g_LastSummonTime) >= 600000 Then ; 600000 ms = 10 minutes
        Local $lPlayerID = GetMyID()

        ; Vérifie si le joueur a la maladie d'invocation active
        Local $hasSickness = Agent_GetAgentEffectInfo($lPlayerID, $GC_I_SKILL_ID_SUMMONING_SICKNESS, "HasEffect")

        If Not $hasSickness Then
            UseSummoningStone()
            $g_LastSummonTime = TimerInit()
        EndIf
    EndIf
EndFunc

; Vérifie toutes les 10 secondes si 10 minutes sont passées
AdlibRegister("_CheckSummoningTimer", 10000)




; === Options ===
Global Const $doLoadLoggedChars = True
Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)

; === Globals ===
Global $charName = ""
Global $ProcessID = ""
Global $timer = TimerInit()
Global $EnableChestFarm = False
Global $BotRunning = False
Global $Bot_Core_Initialized = False
Global $g_bAutoStart = False

; ===========================================
#Region === Initialization & GUI ===
; ===========================================

; Parse command line args
For $i = 1 To $CmdLine[0]
    If $CmdLine[$i] = "-character" And $i < $CmdLine[0] Then
        $charName = $CmdLine[$i + 1]
        $g_bAutoStart = True
        ExitLoop
    EndIf
Next

; ------------- GUI --------------
#include "C:\Users\yoann\Desktop\GW & co\2025\GwAu3-main\Scripts\GUI\Gui_BDS.au3"

; Auto-start logic if character name was provided via command line
If $g_bAutoStart And $charName <> "" Then
    Out("Auto-starting bot for character: " & $charName)

    If Core_Initialize($charName, True) = 0 Then
        MsgBox(0, "Error", "Could not Find a Guild Wars client with a Character named '" & $charName & "'")
        _Exit()
    EndIf

    Local $hGWWindow = Core_GetGuildWarsWindow()
    If $hGWWindow <> 0 Then
        ControlSend($hGWWindow, '', '', '{Enter}')
        Out("Sent Enter key to load character")
        Sleep(3000)
    Else
        Out("Warning: Could not get Guild Wars window handle")
    EndIf

    $Bot_Core_Initialized = True
    $BotRunning = True

    GUICtrlSetData($Button, "Pause")
    GUICtrlSetFont(-1, 10, 400, 0, "Times New Roman")
    WinSetTitle($mainGui, "", Player_GetCharname() & " - Sky BDS Bot Farmer")

    GUICtrlSetState($Builds, $GUI_CHECKED)
    GUICtrlSetState($RenderingBox, $GUI_ENABLE)
    GUICtrlSetState($Input, $GUI_DISABLE)
    GUICtrlSetState($HardmodeCheckbox, $GUI_DISABLE)
    GUICtrlSetState($Builds, $GUI_DISABLE)

    UpdateStatistics()
EndIf

While Not $BotRunning
    Sleep(100)
WEnd

; --- Préparation du plan de route (steps) ---
;InitializeSteps()

While True
    If $BotRunning Then
	Friend_SetOfflineStatus()	
	Out("OFFLINE MODE")
        MainFarm()
    Else
        Sleep(1000)
    EndIf
WEnd


; ===========================================
#Region === Core Farming Loop ===
; ===========================================
Func MainFarm()
    Setup()
    GoToDungeon()
    TakeQuest()
    EnterFirstRun()
    CombatLoop()
EndFunc ;==> MainFarm

; =============================
; Function: Setup
; =============================
Func Setup()

	
    ; Load builds on first run
    If GUICtrlRead($Builds) = $GUI_CHECKED And $RunCount = 0 And $Buildsloaded = 0 Then
        Out("Travelling to Great Temple of Balthazar")
		Sleep(5000)
        RndTravel($Town_ID_Great_Temple_of_Balthazar)
        Sleep(2000)


    EndIf

    ; Travel to Gadd’s Encampment
    If Map_GetMapID() <> $ID_Vloxs_Fall Then


        If $Stucktimer = 0 Then
            If $mapindicator = 1 Then
                Sleep(200)
                $mapindicator = 0
				        Out("Travelling to Vloxs Fall")
                RndTravel($ID_Vloxs_Fall)
            Else
                Sleep(200)
                $mapindicator = 1
				        Out("Travelling to Vloxs Fall")
                RndTravel2($ID_Vloxs_Fall)
            EndIf
        Else
            $mapindicator = 0
			        Out("Travelling to Vloxs Fall")
            RndTravel($ID_Vloxs_Fall)
        EndIf

        Sleep(2000)
    EndIf
	        If CountSlots() < 5 Then
            Out("Inventaire plein, arrêt du farm")
            Inventory()
        EndIf
    ; HardMode
    If GUICtrlRead($HardmodeCheckbox) = $GUI_CHECKED Then
        Game_SwitchMode($DIFFICULTY_HARD)
    Else
        Game_SwitchMode($DIFFICULTY_NORMAL)
    EndIf
	
	    ; === Clear Quest ===
;    Quest_AbandonQuest(0x339)
;    Out("Quest Cleared")


EndFunc ;==> Setup


Func Prepare()
	        ; Reset heroes
        Party_KickAllHeroes()
        Sleep(500)

        Out("Player skillbar loaded")

        ; === Add Heroes & Load Skillbars ===
        Out("Add Heroes")

        ; Livia
        Party_AddHero($HERO_ID_Livia)
        Sleep(500)
        Out("Load Livia's Skillbar")
        Attribute_LoadSkillTemplate("OAhjYYHbIPP1qqdwSUGmcSTrKA", 1)
        Sleep(500)
        Party_SetHeroAggression(1, 0)
        Sleep(500)
        Out("Livia ready!")

        ; Norgu
        Party_AddHero($HERO_ID_Norgu)
        Sleep(500)
        Out("Load Norgu's Skillbar")
        Attribute_LoadSkillTemplate("OQhkAgBsgGK0LAJQeWOgpDCYRwFD", 2)
        Sleep(500)
        Party_SetHeroAggression(2, 0)
        Sleep(500)
        Out("Norgu ready!")

        ; Olias
        Party_AddHero($HERO_ID_Olias)
        Sleep(500)
        Out("Load Olias's Skillbar")
        Attribute_LoadSkillTemplate("OANEUshd9JJHUFQFoAWVFQY0sFC", 3)
        Sleep(500)
        Party_SetHeroAggression(3, 0)
        Sleep(500)
        Out("Olias ready!")

        ; Razah
        Party_AddHero($HERO_ID_Razah)
        Sleep(500)
        Out("Load Razah's Skillbar")
        Attribute_LoadSkillTemplate("OQhkAsC8gFKDNY6lDMd40hQG4iB", 4)
        Sleep(500)
        Party_SetHeroAggression(4, 0)
        Sleep(500)
        Out("Razah ready!")

        ; Xandra
        Party_AddHero($HERO_ID_Xandra)
        Sleep(500)
        Out("Load Xandra's Skillbar")
        Attribute_LoadSkillTemplate("OAOj8YgM5OYTrX48xBNRuOzACA", 5)
        Sleep(500)
        Party_SetHeroAggression(5, 1)
        Sleep(500)
        Out("Xandra ready!")

        ; Master of Whispers
        Party_AddHero($HERO_ID_Master)
        Sleep(500)
        Out("Load Master of Whisper's Skillbar")
        Attribute_LoadSkillTemplate("OAhjQkGZIT3BVVCPSTTODTjTciA", 6)
        Sleep(500)
        Party_SetHeroAggression(6, 1)
        Sleep(500)
        Out("Master of Whisper ready!")

        ; Gwen
        Party_AddHero($HERO_ID_Gwen)
        Sleep(500)
        Out("Load Gwen's Skillbar")
        Attribute_LoadSkillTemplate("OQhkAsC8gFKzJY6lDMd40hQG4iB", 7)
        Sleep(500)
        Party_SetHeroAggression(7, 1)
        Sleep(500)
        Out("Gwen ready!")

        $Buildsloaded = 1
Endfunc 

; =============================
; Function: GoToDungeon
; =============================
Func GoToDungeon()
    Local $Stucktimer = TimerInit()

    ; === Exit to Map ===
	MoveTo(16448, 14830)
	MoveTo(15827, 13368)
	MoveTo(15505.38, 12460.59)
    Out("Going Out")
    Do
        Sleep(1000)
    Until Map_GetMapID() == $ID_Arbor_Bay
    Sleep(1000)

    ; === Get Asura Blessing ===
    Out("Moving to Asura beacon")
	
MoveTo(16327, 11607)
    Out("Getting Asura Blessing")
    Sleep(500)
    Agent_GoNPC(GetNearestNPCToAgent(-2))
    Sleep(2000)
    Ui_Dialog(0x84)
    Sleep(1000)

; === Waypoints ===
DoStep(1,13455.43, 10678, "aggro")
DoStep(2, 9850, 5025, "aggro")
DoStep(3, 11736.00, 70, "move")
DoStep(4, 10782.86, -3321, "aggro")
DoStep(5, 8360.94, -6550, "aggro")
DoStep(6,10382.85, -12342 , "aggro")
DoStep(7, 10080.30, -13995, "aggro")
DoStep(8, 10667.00, -16116, "aggro")
DoStep(9, 10747.49, -17546, "aggro")
DoStep(10, 11156, -17802, "aggro")


Sleep(1000)

EndFunc ;==> GoToDungeon


; =============================
; Function: TakeQuest
; =============================
Func TakeQuest()
    Local $questID = 0x324
    Sleep(500)


    ; --- Cas 1 : Quête peut être récompensée ---
    If Quest_GetQuestInfo($questID, "IsCompleted") Then
        Out("Quest can be rewarded at Shandra, completing it ✅")
		MoveTo(12056.00,-17882)
        Agent_GoNPC(GetNearestNPCToAgent(-2))
        Sleep(500)
        HandleShandra("reward", $questID)
        ReloadQuest()
        TakeQuestNewRun()
        Re_Enter()

    ; --- Cas 2 : Quête active mais incomplète ---
    ElseIf Quest_GetQuestInfo($questID, "QuestID") Then
        Out("Quest already taked 📜")
		        Out("Enter in dungeon")

    ; --- Cas 3 : Quête pas dans le journal ---
    Else
        Out("Quest not yet accepted at Shandra, taking it now 📜")
		MoveTo(12056.00,-17882)
        Agent_GoNPC(GetNearestNPCToAgent(-2))
        Sleep(500)
        HandleShandra("take", $questID)
    EndIf

    Sleep(500)
EndFunc ;==> TakeQuest



Func CombatLoop()
    Out("Starting BDS Farm")

    While $BotRunning
        ; ===============================
        ; Vérification inventaire
        ; ===============================
        If CountSlots() < 5 Then
            Out("Inventaire plein, arrêt du farm")
            Inventory()
            ExitLoop
        EndIf

        ; ===============================
        ; Gestion intelligente de la quête
        ; ===============================
        Local $questID = 0x324

        If Quest_GetQuestInfo($questID, "IsCompleted") Then
            ; Quête terminée → rendre, recharger, reprendre
            HandleShandra("reward", $questID)
            ReloadQuest()
            TakeQuestNewRun()
            Re_Enter()

        ElseIf Not Quest_GetQuestInfo($questID, "QuestID") Then
            ; Quête absente du log → la reprendre
            HandleShandra("take", $questID)
            Re_Enter()
        EndIf

        ; ===============================
        ; Lancer un run complet
        ; ===============================
        ResetRun()
        FirstStage()
        SecondStage()
        LastStep()

        ; ===============================
        ; Comptabilisation du run
        ; ===============================
        If Agent_GetAgentInfo(-2, "IsDead") Then
            $FailCount += 1
            Out("Run échoué !")
        Else
            $SuccessCount += 1
        EndIf

        $RunCount += 1
        GUICtrlSetData($RunsLabel, "Runs: " & $RunCount)
        UpdateStatistics()
        Sleep(2000)
    WEnd
EndFunc


; ===========================================
#Region === Stages ===
; ===========================================
Func EnterFirstRun()

MoveTo(11177, -17683)
	MoveTo(10218, -18864)
	MoveTo(9519, -19968)
	MoveTo(9240.07, -20260.95)
	    Do
			Sleep(500)
    Until Map_GetMapID() = $ID_SoO_lvl1

EndFunc ;==> EnterFirstRun


Func FirstStage()
If Not WaitForMapLoad($ID_SoO_lvl1) Then
	Out("Erreur : échec de chargement de la carte SoO_lvl1" & @CRLF)
		EnterFirstRun()
	Return
EndIf
    If Map_GetMapID() = $ID_SoO_lvl1 Then
        Out("Mission Map loaded")
    Else
        Out("Mission Map not loaded")
    EndIf
    $RunTimer = TimerInit() ; ✅ Start chrono
    ; === Vérifier si la quête est active ===
    Local $questID = 0x324 ; ID de la quête
    If Not Quest_GetQuestInfo($questID, "QuestID") Then
        ; Si la quête n'est pas active, on reprend la quête et réentre dans le donjon
        RetakeQuest()
        Return ; Sortir de la fonction pour éviter d'exécuter le reste avant de retourner dans le donjon
    EndIf
	


    Out("Moving to Beacon of Droknar")
    DoStep(11, -11686, 10427, "move")
    Out("Getting Dwarven Blessing")
    Agent_GoNPC(GetNearestNPCToAgent(-2))
    Sleep(1000)
    Ui_Dialog(0x84)
    Sleep(1000)
    Powerup()
		
	UseSummoningStone()

    $ChestFarmActive = True
    DoStep(12, -10486, 9587, "aggro")
    DoStep(13, -6196, 10260, "aggro")
    DoStep(14, -3819, 11737, "aggro")
    DoStep(15, -1123, 13649, "aggro")
    DoStep(16, 2734, 16041, "aggro")
    DoStep(17, 3877, 14790, "aggro")
    DoStep(18, 5569.52, 13057, "aggro")
    DoStep(19, 6780, 13039, "aggro")
    DoStep(20, 8056, 12349, "aggro")
    DoStep(21, 9232, 11483, "aggro")
    Out("Kill Bandit")
    DoStep(22, 6799, 11264, "aggro")
    PickupLoot()
    DoStep(23, 11298, 13891, "aggro")
    DoStep(24, 13255, 15175, "aggro")
    DoStep(25, 15935, 17304, "aggro")
    DoStep(26, 17161, 13551, "aggro")
    DoStep(27, 16100, 11992, "aggro")
    DoStep(28, 15637, 9493, "aggro")
    DoStep(29, 14287, 7751, "aggro")
    DoStep(30, 14130, 6263, "aggro")

    MoveTo(15094.00, 5493)
    Agent_GoSignpost(GetNearestSignpostToAgent(-2))
    Agent_GoSignpost(GetNearestSignpostToAgent(-2))
    Sleep(500)
    Out("Door Opened")
    DoStep(31, 15331, 4637, "aggro")
    DoStep(32, 16494, 2662, "aggro")
    DoStep(33, 18270, 1439, "aggro")
    Out("Going through portal")
	DoStep(34,19812,902, "aggro")
	DoStep(35,20000,950, "aggro")
	MoveTo(20400,1300)

    ; Transition vers étage suivant
    Out("FirstStage : Check")
    Out("Travelling to Level 2")
    $ChestFarmActive = False	
EndFunc ;==> FirstStage


Func SecondStage()
If Not WaitForMapLoad($ID_SoO_lvl2) Then
	Out("Erreur : échec de chargement de la carte SoO_lvl2" & @CRLF)
		MoveTo(20400,1300)
		Return
EndIf
    Out("✅Level 2 : Uploaded !")
    $ChestFarmActive = True
    Out("Moving to Beacon of Droknar")
    DoStep(36, -14076, -19457, "move")
    Sleep(1000)
    Out("Getting Dwarven Blessing")
    Agent_GoNPC(GetNearestNPCToAgent(-2))
    Sleep(1000)
    Ui_Dialog(0x84)
    Sleep(1000)
    Powerup()
    	
	UseSummoningStone()
    ; === Level 2 ===   
    Out("Kill Bandit")
    DoStep(37,-14050.64,-18215.56,"aggro")
    DoStep(38, -14215, -17456,"clean")
    DoStep(39, -16191, -16740,"clean")                                                                                                                                                         
	
    Out("Open torch chest")
    MoveTo(-14709, -16548)
	Sleep(500)
	Agent_GoSignpost(GetNearestSignpostToAgent(-2))
	Sleep(500)
		Agent_GoSignpost(GetNearestSignpostToAgent(-2))
	Sleep(500)
    Out("Pick up torch")
	Sleep(500)
PickupLootTorch()
PickupLootTorch()


;=====Before Fight=====
	MoveTo(-11205,-17130)
	DropTorch()
    DoStep(40, -9259, -17322, "aggro")
	PickupLootTorch()
    DoStep(41, -10963, -14989, "move")
	MoveTo(-11248,-14596)
 _GetBraziers_Lvl2_Part1()
	
    Out("Drop torch")
Party_CancelAll()	
DropTorch()

    Sleep(500)
    Out("Kill group")
    DoStep(42, -9358, -12411, "aggro")
    DoStep(43, -10143, -11136, "aggro")
    DoStep(44, -8871, -9951, "aggro")
    DoStep(45, -7722, -11522, "aggro")
    Sleep(1000)
PickupLootTorch()
    Sleep(2000)
    DoStep(46, -11043,-7750, "aggro")
	PickupLootTorch()
	DoStep(47, -11058,-4487, "aggro")
	PickupLootTorch()
    DoStep(48, -6721,-4209, "move")
    DoStep(49, -6531,-3469, "move")
 _GetBraziers_Lvl2_Part2()

    Out("Drop torch")
    DropTorch()
    Sleep(500)

    DoStep(50, -6481, -2668, "aggro")
    PickupLoot()
    DoStep(51, -11204, -4331, "aggro")
    DoStep(52, -14674, -4442, "aggro")
    DoStep(53, -16007, -8640, "aggro")
    DoStep(54, -17735, -9337, "aggro")
	DoStep(55, -18035, -9237, "aggro")

    Out("Open Door")
    MoveTo(-18725, -9171)	
    Sleep(1000)
    Agent_GoSignpost(GetNearestSignpostToAgent(-2))
    Sleep(500)
    Agent_GoSignpost(GetNearestSignpostToAgent(-2))
	Sleep(500)
		
    Out("SecondStage : Check")
    Out("Going through portal")
    MoveTo(-19300, -8200)
    $ChestfarmActive = False
EndFunc ;==> SecondStage

; === Troisième étage ===
Func LastStep()
    If Not WaitForMapLoad($ID_SoO_lvl3) Then
        Out("Erreur : échec de chargement de la carte SoO_lvl3" & @CRLF)
        MoveTo(-19300, -8200)
        Return
    EndIf
    Out("✅Level 3 : Uploaded !")
    $ChestFarmActive = True

    DoStep(56, 17325, 18961, "aggro")
    MoveTo(17544, 18810)
    Out("Getting Dwarven Blessing")
    Agent_GoNPC(GetNearestNPCToAgent(-2))
    Sleep(1000)
    Ui_Dialog(0x84)
    Sleep(1000)

    Powerup()
    UseSummoningStone()

    ; === Boucle principale du run ===
    While $ChestFarmActive

        ; === Exécution du reste des étapes ===
        DoStep(57, 17544, 18810, "aggro")
        DoStep(58, 9452, 18513, "aggro")
        DoStep(59, 8908, 17239, "aggro")
        DoStep(60, 6527, 12936, "aggro")
        DoStep(61, 3025, 8401, "aggro")
        DoStep(62, 949, 7412, "aggro")
        DoStep(63, -347, 6459, "aggro")
        DoStep(64, -1265, 7891, "aggro")

        Out("Getting Dwarven Blessing")
        Agent_GoNPC(GetNearestNPCToAgent(-2))
        Sleep(1000)
        Ui_Dialog(0x84)
        Sleep(1000)

        DoStep(65, -5923.93, 6006, "aggro")
        DoStep(66, -7993.65, 4588, "clean")
Out("Go to take torch !")
        MoveTo(-10192.24, 3092)
		Out("Waypoint 1")
        MoveTo(-4723, 6703)
		Out("Waypoint 2")
        MoveTo(-1280, 7880)
		Out("Waypoint 3")
        MoveTo(3089.73, 8511)
		Out("Waypoint 4")
        MoveTo(4963, 9974)
		Out("Waypoint 5")
        MoveTo(9918.64, 19108)
		Out("Waypoint 6")
        MoveTo(14709, 19526)
		Out("Waypoint 7")
        MoveTo(16111.00, 17556)
Out("Waypoint 8")
        Out("Open torch chest")
        Agent_GoSignpost(GetNearestSignpostToAgent(-2))
        Sleep(1000)
        PickupLootTorch()
        PickupLootTorch()
        _GetBraziers_Lvl3()

        DoStep(67, -10637, 2904, "aggro")
        DoStep(68, -9806, 2370, "aggro")
        PickupLoot()
        DoStep(69, -2189.49, 8516, "move")
        DoStep(70, -4445.94, 6591, "move")
        DoStep(71, -8732.38, 6245, "aggro")

        Out("Open dungeon door")
        Sleep(500)
        MoveTo(-9284, 6360)
        Agent_GoSignpost(GetNearestSignpostToAgent(-2))
        Agent_GoSignpost(GetNearestSignpostToAgent(-2))	

        ; === Boss Fight Loop ===
        DoStep(72, -9926, 8007, "aggro")
        DoStep(73, -8490, 9370, "aggro")
        DoStep(74, -10279, 11402, "clean")
        UseSummoningStone()
		Dostep(75,-14134.03,14665,"move")
        DoStep(76, -15616.19,15433, "move")
        DoStep(77,-16806.99,15543 , "move")
        DoStep(78, -16670.49,15511, "clean")		
        ;DoStep(79, -15967.96,17306, "clean")
        ; === Chest & Loot ===
        Out("Fendi Chest")
        MoveTo(-15753, 17417)
        MoveTo(-15743, 16832)
        Sleep(1000)
        Agent_GoSignpost(GetNearestSignpostToAgent(-2))
        Sleep(2000)

        ; === Statistiques du run ===
        $RunTime = TimerDiff($RunTimer)
        $RunTimeCalc = Round($RunTime / 1000)
        ReDim $AvgTime[UBound($AvgTime) + 1]
        $AvgTime[UBound($AvgTime) - 1] = $RunTimeCalc
        CalculateFastestTime()
        CalculateAverageTime()

        Out("Run réussi en " & $RunTimeCalc & "s")
        GUICtrlSetData($FastTimeLabel, "Fastest Time: " & $RunTimeMinutes & " min  " & $RunTimeSeconds & " sec")
        GUICtrlSetData($AvgTimeLabel, "Average Time: " & $AvgRunTimeMinutes & " min  " & $AvgRunTimeSeconds & " sec")

        Out("Pick Up Drops")
        PickupLoot()

        ; === Fin du run ===
        Out("Wait for Reload")
        $ChestFarmActive = False
    WEnd

    ; === Retour Shandra ===
    Local $questID = 0x324
    MoveTo(-15857, 17118)
    HandleShandra("reward", $questID)
    Do
        Sleep(500)
    Until Map_GetMapID() == $ID_Arbor_Bay
    Sleep(2000)
EndFunc ;==> LastStep



#EndRegion Stages

; ===========================================
#Region === Quest section ===
; ===========================================

Func TakeQuestNewRun()
    Local $questID = 0x324
    Out("Starting next run")

    If Map_GetMapID() == $ID_Arbor_Bay Then
        Out("Map Loaded : Go to Shandra")
    EndIf
    MoveTo(12056, -17882)	    
    HandleShandra("take", $questID)
    Sleep(500)
EndFunc

Func ReloadQuest()
    Out("Setup Next Run")
    Re_Enter()
    Out("Going Out")
	MoveTo(-15000, 8600)
	MoveTo(-15650, 8900)
    Do
        Sleep(500)
    Until Map_GetMapID() == $ID_Arbor_Bay
EndFunc

Func RetakeQuest()
    Out("Another try")
	    Out("Going Out")
	MoveTo(-15000, 8600)
	MoveTo(-15650, 8900)
	Sleep(2000)
	TakeQuestNewRun()	
    Re_Enter()
    Sleep(2000)
EndFunc

Func Re_Enter()
    Out("Re-entering dungeon via portal")
	MoveTo(11177, -17683)
	MoveTo(10218, -18864)
	MoveTo(9519, -19968)
	MoveTo(9240.07, -20260.95)
    Do
        Sleep(500)
    Until Map_GetMapID() == $ID_SoO_lvl1
    Out("Map Completly Loaded")
EndFunc
#EndRegion Quest