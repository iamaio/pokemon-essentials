#===============================================================================
# If the user attacks before the target, or if the target switches in during the 
# turn that Fishious Rend is used, its base power doubles. (Fishious Rend, Bolt Beak)
#===============================================================================
class PokeBattle_Move_177 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg*=2 if !target.movedThisRound?
    return baseDmg
  end
end

#===============================================================================
# The user attacks by slamming its body into the target. The higher the user's 
# Defense, the more damage it can inflict on the target. (Body Press)
#===============================================================================
class PokeBattle_Move_175 < PokeBattle_Move
  def pbGetAttackStats(user,target)
    atk=user.defense
    return user.defense, user.stages[PBStats::DEFENSE]+6
  end
end

#===============================================================================
# The user sharply raises the target's Attack and Sp. Atk stats by decorating 
# the target. (Decorate)
#===============================================================================
class PokeBattle_Move_179 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    failed = true
    targets.each do |b|
      next if (!b.pbCanRaiseStatStage?(PBStats::ATTACK,user,self) && !b.pbCanRaiseStatStage?(PBStats::SPATK,user,self))
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    if target.pbCanRaiseStatStage?(PBStats::ATTACK,user,self)
      target.pbRaiseStatStage(PBStats::ATTACK,2,user)
    end
    if target.pbCanRaiseStatStage?(PBStats::SPATK,user,self)
      target.pbRaiseStatStage(PBStats::SPATK,2,user)
    end    
  end
end



#===============================================================================
# Raise speed by one stage. Fails if user is not a Morpeko. Base Type is dark
# if Morpeko's Form is Hangry Form (Aura Wheel)
#===============================================================================
class PokeBattle_Move_180 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::SPEED,1]
  end

  def pbMoveFailed?(user,targets)
    if NEWEST_BATTLE_MECHANICS && isConst?(@id,PBMoves,:AURAWHEEL)
      if !isConst?(user.species,PBSpecies,:MORPEKO) &&
         !isConst?(user.effects[PBEffects::TransformSpecies],PBSpecies,:MORPEKO)
        @battle.pbDisplay(_INTL("But {1} can't use the move!",user.pbThis))
        return true
      end
    end
    return false
  end

  def pbBaseType(user)
    ret = getID(PBTypes,:NORMAL)
    case user.form
    when 0
      ret = getConst(PBTypes,:ELECTRIC) || ret
	  pbWait(1)
    when 1
      ret = getConst(PBTypes,:DARK) || ret
	  pbWait(1)
    end
    return ret
  end  
end


#===============================================================================
# Prevents both the user and the target from escaping. (Jaw Lock)
#===============================================================================
class PokeBattle_Move_181 < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    if target.effects[PBEffects::JawLockUser]<0 && !target.effects[PBEffects::JawLock] &&
      user.effects[PBEffects::JawLockUser]<0 && !user.effects[PBEffects::JawLock]
      user.effects[PBEffects::JawLock] = true
      target.effects[PBEffects::JawLock] = true
      user.effects[PBEffects::JawLockUser] = user.index
      target.effects[PBEffects::JawLockUser] = user.index
      @battle.pbDisplay(_INTL("Neither Pokémon can run away!"))
    end
  end
end



#===============================================================================
# User is protected against damaging moves this round. Decreases the Defense of
# the user of a stopped contact move by 2 stages. (Obstruct)
#===============================================================================
class PokeBattle_Move_184 < PokeBattle_ProtectMove
  def initialize(battle,move)
    super
    @effect = PBEffects::Obstruct
  end
end



#===============================================================================
# Ignores move redirection from abilities and moves. (Snipe Shot)
#===============================================================================
class PokeBattle_Move_186 < PokeBattle_Move
end



#===============================================================================
# Consumes berry and raises the user's Defense by 2 stages. (Stuff Cheeks)
#===============================================================================
class PokeBattle_Move_187 < PokeBattle_Move
  def pbEffectGeneral(user)
    if user.item==0 || !pbIsBerry?(user.item)
      @battle.pbDisplay("But it failed!")
      return -1
    end
    if user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self)
      user.pbRaiseStatStage(PBStats::DEFENSE,2,user)
    end
    user.pbHeldItemTriggerCheck(user.item,false)
    user.pbConsumeItem(true,true,false) if user.item>0
    user.pbRemoveItem if pbIsBerry?(target.item)
  end 
end



#===============================================================================
# Forces all active Pokémon to consume their held berries. This move bypasses
# Substitutes. (Tea Time)
#===============================================================================
class PokeBattle_Move_188 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    @validTargets = []
    @battle.eachBattler do |b|
      next if !b.item == 0 || !pbIsBerry?(b.item)
      @validTargets.push(b.index)
    end
    if @validTargets.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    @battle.pbDisplay(_INTL("It's tea time! Everyone dug in to their Berries!"))
    return false
  end
  
  def pbFailsAgainstTarget?(user,target)
    return false if @validTargets.include?(target.index)
    return true if target.semiInvulnerable?
  end
  
  def pbEffectAgainstTarget(user,target)
    target.pbHeldItemTriggerCheck(user.item,false)
    target.pbConsumeItem(true,true,false) if user.item>0
    target.pbRemoveItem if pbIsBerry?(target.item)
  end
end

#===============================================================================
# Target becomes Psychic type. (Magic Powder)
#===============================================================================
class PokeBattle_Move_200 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if !target.canChangeType? ||
       !target.pbHasOtherType?(getConst(PBTypes,:PSYCHIC))
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    newType = getConst(PBTypes,:PSYCHIC)
    target.pbChangeTypes(newType)
    typeName = PBTypes.getName(newType)
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",target.pbThis,typeName))
  end
end

#===============================================================================
# Swaps barriers, veils and other effects between each side of the battlefield.
# (Court Change)
#===============================================================================
class PokeBattle_Move_201 < PokeBattle_Move
    def pbEffectAgainstTarget(user,target)
    fail=false
    neffectsuser=[]
    beffectsuser=[]
    neffectsopp=[]
    beffectsopp=[]
    for i in 0...2
      i==0 ? a=user : a=target
      i==0 ? b=neffectsuser : b=neffectsopp
      i==0 ? c=beffectsuser : c=beffectsopp
      fail=true if a.pbOwnSide.effects[PBEffects::Reflect] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Reflect])
      fail=true if a.pbOwnSide.effects[PBEffects::LightScreen] > 0
      b.push(a.pbOwnSide.effects[PBEffects::LightScreen])
      fail=true if a.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
      b.push(a.pbOwnSide.effects[PBEffects::AuroraVeil])
      fail=true if a.pbOwnSide.effects[PBEffects::SeaOfFire] > 0
      b.push(a.pbOwnSide.effects[PBEffects::SeaOfFire])
      fail=true if a.pbOwnSide.effects[PBEffects::Swamp] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Swamp])
      fail=true if a.pbOwnSide.effects[PBEffects::Rainbow] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Rainbow])
      fail=true if a.pbOwnSide.effects[PBEffects::Mist] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Mist])      
      fail=true if a.pbOwnSide.effects[PBEffects::Safeguard] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Safeguard])
      fail=true if a.pbOwnSide.effects[PBEffects::Spikes] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Spikes])
      fail=true if a.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
      b.push(a.pbOwnSide.effects[PBEffects::ToxicSpikes])      
      fail=true if a.pbOwnSide.effects[PBEffects::Tailwind] > 0
      b.push(a.pbOwnSide.effects[PBEffects::Tailwind])
      fail=true if a.pbOwnSide.effects[PBEffects::StealthRock]
      c.push(a.pbOwnSide.effects[PBEffects::StealthRock])
      fail=true if a.pbOwnSide.effects[PBEffects::StickyWeb]
      c.push(a.pbOwnSide.effects[PBEffects::StickyWeb])      
    end
    if !fail
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    else
      user.pbOwnSide.effects[PBEffects::Reflect] = neffectsopp[0]
      target.pbOwnSide.effects[PBEffects::Reflect] = neffectsuser[0]
      user.pbOwnSide.effects[PBEffects::LightScreen] = neffectsopp[1]
      target.pbOwnSide.effects[PBEffects::LightScreen] = neffectsuser[1]
      user.pbOwnSide.effects[PBEffects::AuroraVeil] = neffectsopp[2]
      target.pbOwnSide.effects[PBEffects::AuroraVeil] = neffectsuser[2]
      user.pbOwnSide.effects[PBEffects::SeaOfFire] = neffectsopp[3]
      target.pbOwnSide.effects[PBEffects::SeaOfFire] = neffectsuser[3]
      user.pbOwnSide.effects[PBEffects::Swamp] = neffectsopp[4]
      target.pbOwnSide.effects[PBEffects::Swamp] = neffectsuser[4]
      user.pbOwnSide.effects[PBEffects::Rainbow] = neffectsopp[5]
      target.pbOwnSide.effects[PBEffects::Rainbow] = neffectsuser[5]
      user.pbOwnSide.effects[PBEffects::Mist] = neffectsopp[6]
      target.pbOwnSide.effects[PBEffects::Mist] = neffectsuser[6]
      user.pbOwnSide.effects[PBEffects::Safeguard] = neffectsopp[7]
      target.pbOwnSide.effects[PBEffects::Safeguard] = neffectsuser[7]
      user.pbOwnSide.effects[PBEffects::Spikes] = neffectsopp[8]
      target.pbOwnSide.effects[PBEffects::Spikes] = neffectsuser[8]
      user.pbOwnSide.effects[PBEffects::ToxicSpikes] = neffectsopp[9]
      target.pbOwnSide.effects[PBEffects::ToxicSpikes] = neffectsuser[9]
      user.pbOwnSide.effects[PBEffects::Tailwind] = neffectsopp[10]
      target.pbOwnSide.effects[PBEffects::Tailwind] = neffectsuser[10]
      user.pbOwnSide.effects[PBEffects::StealthRock] = beffectsopp[0]
      target.pbOwnSide.effects[PBEffects::StealthRock] = beffectsuser[0]
      user.pbOwnSide.effects[PBEffects::StickyWeb] = beffectsopp[1]
      target.pbOwnSide.effects[PBEffects::StickyWeb] = beffectsuser[1]
      @battle.pbDisplay(_INTL("{1} swapped the battle effects affecting each side of the field!",user.pbThis))
      return 0
    end
  end
end

#===============================================================================
# Raises all user's stats by 1 stage in exchange for the user losing 1/3 of its 
# maximum HP, rounded down. Fails if the user would faint. (Clangorous Soul) 
#===============================================================================
class PokeBattle_Move_202 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.hp<=(user.totalhp/3) ||
      !user.pbCanRaiseStatStage?(PBStats::ATTACK,user,self) ||
      !user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self) ||
      !user.pbCanRaiseStatStage?(PBStats::SPEED,user,self) ||
      !user.pbCanRaiseStatStage?(PBStats::SPATK,user,self) ||
      !user.pbCanRaiseStatStage?(PBStats::SPDEF,user,self)      
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
  
  def pbEffectGeneral(user)
    if user.pbCanRaiseStatStage?(PBStats::ATTACK,user,self)
      user.pbRaiseStatStage(PBStats::ATTACK,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self)
      user.pbRaiseStatStage(PBStats::DEFENSE,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::SPEED,user,self)
      user.pbRaiseStatStage(PBStats::SPEED,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::SPATK,user,self)
      user.pbRaiseStatStage(PBStats::SPATK,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::SPDEF,user,self)
      user.pbRaiseStatStage(PBStats::SPDEF,1,user)
    end
    user.pbReduceHP(user.totalhp/3,false)
  end   
end

#===============================================================================
# Decrease 1 stage of speed and gives and weakens target to fire moves
#===============================================================================
class PokeBattle_Move_203 < PokeBattle_Move  
  def pbEffectAgainstTarget(user,target)
    if !target.pbCanLowerStatStage?(PBStats::SPEED,target,self) && !target.effects[PBEffects::TarShot]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if target.pbCanLowerStatStage?(PBStats::SPEED,target,self)
      target.pbLowerStatStage(PBStats::SPEED,1,target)
    end
    if target.effects[PBEffects::TarShot]==false
      target.effects[PBEffects::TarShot]=true
      @battle.pbDisplay(_INTL("{1} became weaker to fire!",target.pbThis))
    end
  end   
end


#===============================================================================
# Life Dew
#===============================================================================
class PokeBattle_Move_204 < PokeBattle_Move
  def healingMove?; return true; end    
  def worksWithNoTargets?; return true; end
  
  def pbMoveFailed?(user,targets)
    failed = true
    @battle.eachSameSideBattler(user) do |b|
      next if b.hp == b.totalhp
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
  
  def pbFailsAgainstTarget?(user,target)
    if target.hp==target.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",target.pbThis))
      return true
    elsif !target.canHeal?
      @battle.pbDisplay(_INTL("{1} is unaffected!",target.pbThis))
      return true
    end
    return false
  end
  
  def pbEffectAgainstTarget(user,target)
    hpGain = (target.totalhp/4.0).round
    target.pbRecoverHP(hpGain)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",target.pbThis))  
  end
  
  def pbHealAmount(user)
    return (user.totalhp/4.0).round
  end
end

#===============================================================================
# Octolock
#===============================================================================
class PokeBattle_Move_205 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if target.effects[PBEffects::OctolockUser]>=0 || (target.damageState.substitute && !ignoresSubstitute?(user))
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if NEWEST_BATTLE_MECHANICS && target.pbHasType?(:GHOST)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.effects[PBEffects::OctolockUser] = user.index
    target.effects[PBEffects::Octolock] = true
    @battle.pbDisplay(_INTL("{1} can no longer escape!",target.pbThis))
  end
end


#===============================================================================
# No Retreat
#===============================================================================
class PokeBattle_Move_206 < PokeBattle_MultiStatUpMove
  def pbMoveFailed?(user,targets)
    if user.effects[PBEffects::NoRetreat]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if !user.pbCanRaiseStatStage?(PBStats::ATTACK,user,self,true) &&
       !user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self,true) &&
       !user.pbCanRaiseStatStage?(PBStats::SPATK,user,self,true) &&
       !user.pbCanRaiseStatStage?(PBStats::SPDEF,user,self,true) &&
       !user.pbCanRaiseStatStage?(PBStats::SPEED,user,self,true)
      return true
      @battle.pbDisplay(_INTL("But it failed!"))
    end
    return false
  end 
  
  def pbEffectGeneral(user)
    if user.pbCanRaiseStatStage?(PBStats::ATTACK,user,self)
      user.pbRaiseStatStage(PBStats::ATTACK,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self)
      user.pbRaiseStatStage(PBStats::DEFENSE,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::SPEED,user,self)
      user.pbRaiseStatStage(PBStats::SPEED,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::SPATK,user,self)
      user.pbRaiseStatStage(PBStats::SPATK,1,user)
    end
    if user.pbCanRaiseStatStage?(PBStats::SPDEF,user,self)
      user.pbRaiseStatStage(PBStats::SPDEF,1,user)
    end
    
    if !(user.effects[PBEffects::MeanLook]>=0 || user.effects[PBEffects::Trapping]>0 ||
       user.effects[PBEffects::JawLock] || user.effects[PBEffects::OctolockUser]>=0)
      user.effects[PBEffects::NoRetreat] = true
      @battle.pbDisplay(_INTL("{1} can no longer escape because it used No Retreat!",user.pbThis))
    end
  end
end 



#===============================================================================
# In singles, this move hits the target twice. In doubles, this move hits each 
# target once. If one of the two opponents protects or while semi-invulnerable 
# or is a Fairy-type Pokémon, it hits the opponent that doesn't protect twice. 
# (Dragon Darts)
#===============================================================================
class PokeBattle_Move_207 < PokeBattle_Move
  def multiHitMove?;           return true; end
  def pbNumHits(user,targets); return 2;    end
end

#===============================================================================
# Jungle Healing
#===============================================================================
class PokeBattle_Move_208 < PokeBattle_Move
  def healingMove?; return true; end

  def pbMoveFailed?(user,targets)
    jglheal = 0
    for i in 0...targets.length
      jglheal += 1 if (targets[i].hp == targets[i].totalhp || !targets[i].canHeal?) && targets[i].status ==PBStatuses::NONE
    end
    if jglheal == targets.length 
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
      target.pbCureStatus
    if target.hp != target.totalhp && target.canHeal?
      hpGain = (target.totalhp/4.0).round
      target.pbRecoverHP(hpGain)
      @battle.pbDisplay(_INTL("{1}'s health was restored.",target.pbThis))
    end
    super
  end
end

#===============================================================================
# Shell Side Arm
#===============================================================================
class PokeBattle_Move_209 < PokeBattle_Move_005
  def initialize(battle,move)
    super
    @calcCategory = 1
  end
  
  def physicalMove?(thisType=nil); return (@calcCategory==0); end
  def specialMove?(thisType=nil);  return (@calcCategory==1); end
    
  def pbOnStartUse(user,targets)
    stageMul = [2,2,2,2,2,2, 2, 3,4,5,6,7,8]
    stageDiv = [8,7,6,5,4,3, 2, 2,2,2,2,2,2]
    defense      = targets[0].defense
    defenseStage = targets[0].stages[PBStats::DEFENSE]+6
    realDefense  = (defense.to_f*stageMul[defenseStage]/stageDiv[defenseStage]).floor
    spdef        = targets[0].spdef
    spdefStage   = targets[0].stages[PBStats::SPDEF]+6
    realSpdef    = (spdef.to_f*stageMul[spdefStage]/stageDiv[spdefStage]).floor
    # Determine move's category
    return @calcCategory = 0 if realDefense<realSpdef
    return @calcCategory = 1 if realDefense>=realSpdef
  end
end

#===============================================================================
# Hits 3 times and always critical. (Surging Strikes)
#===============================================================================
class PokeBattle_Move_210 < PokeBattle_Move_0A0
  def multiHitMove?;           return true; end
  def pbNumHits(user,targets); return 3;    end
  end
  
#===============================================================================
# Terrain Pulse
#===============================================================================
class PokeBattle_Move_211 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain != PBBattleTerrains::None && !user.airborne?
    return baseDmg
  end

  def pbBaseType(user)
    ret = getID(PBTypes,:NORMAL)
    if !user.airborne?
      case @battle.field.terrain
      when PBBattleTerrains::Electric
        ret = getConst(PBTypes,:ELECTRIC) || ret
      when PBBattleTerrains::Grassy
        ret = getConst(PBTypes,:GRASS) || ret
      when PBBattleTerrains::Misty
        ret = getConst(PBTypes,:FAIRY) || ret
      when PBBattleTerrains::Psychic
        ret = getConst(PBTypes,:PSYCHIC) || ret
      end
    end
    return ret
  end

  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    t = pbBaseType(user)
    hitNum = 1 if isConst?(t,PBTypes,:ELECTRIC)
    hitNum = 2 if isConst?(t,PBTypes,:GRASS)
    hitNum = 3 if isConst?(t,PBTypes,:FAIRY)
    hitNum = 4 if isConst?(t,PBTypes,:PSYCHIC)
    super
  end
end

#===============================================================================
# Coaching
#===============================================================================
class PokeBattle_Move_212 < PokeBattle_Move
  
  def pbEffectAgainstTarget(user,target)
    if !target.pbCanRaiseStatStage?(PBStats::ATTACK,target,self) && !target.pbCanRaiseStatStage?(PBStats::DEFENSE,target,self)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if target.pbCanRaiseStatStage?(PBStats::ATTACK,target,self)
      target.pbRaiseStatStage(PBStats::ATTACK,1,user)
    end
    if target.pbCanRaiseStatStage?(PBStats::DEFENSE,target,self)
      target.pbRaiseStatStage(PBStats::DEFENSE,1,user)
    end
  end
end

#===============================================================================
# Scale Shot
#===============================================================================
class PokeBattle_Move_213 < PokeBattle_Move_0C0    
  def pbEffectAfterAllHits(user,target)
    if user.pbCanRaiseStatStage?(PBStats::SPEED,user,self)
      user.pbRaiseStatStage(PBStats::SPEED,1,user)
    end
    if user.pbCanLowerStatStage?(PBStats::DEFENSE,target)
      user.pbLowerStatStage(PBStats::DEFENSE,1,user)
    end
  end
end

#===============================================================================
# Rising Voltage
#===============================================================================
class PokeBattle_Move_214 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain==PBBattleTerrains::Electric &&
                    !target.airborne?
    return baseDmg
  end
end

#===============================================================================
# Grassy Glide
#===============================================================================
class PokeBattle_Move_215 < PokeBattle_Move
end

#===============================================================================
# Misty Explosion
#===============================================================================
class PokeBattle_Move_216 < PokeBattle_Move_0E0
  def pbBaseDamage(baseDmg,user,target)
    if @battle.field.terrain==PBBattleTerrains::Misty
      baseDmg = (baseDmg*1.5).round
    end
    return baseDmg
  end
end

#===============================================================================
# Expanding Force
#===============================================================================
class PokeBattle_Move_217 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 1.5 if @battle.field.terrain==PBBattleTerrains::Psychic
    return baseDmg
  end
end

#===============================================================================
# Meteor Beam
#===============================================================================
class PokeBattle_Move_218 < PokeBattle_TwoTurnMove
  def pbChargingTurnMessage(user,targets)
    @battle.pbDisplay(_INTL("{1} is overflowing with space power!",user.pbThis))
  end

  def pbChargingTurnEffect(user,target)
    if user.pbCanRaiseStatStage?(PBStats::SPATK,user,self)
      user.pbRaiseStatStage(PBStats::SPATK,1,user)
    end
  end
end

#===============================================================================
# Poltergeist
#===============================================================================
class PokeBattle_Move_219 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if target.item!=0
      @battle.pbDisplay(_INTL("{1} is about to be attacked by its {2}!",target.pbThis,target.itemName))
      return false
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return true
  end
end

#===============================================================================
# Steel Roller
#===============================================================================
class PokeBattle_Move_220 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if @battle.field.terrain == PBBattleTerrains::None
	  @battle.pbDisplay(_INTL("But it failed!"))
	  return true 
	end
    return false	
  end
  
  def pbEffectGeneral(user)
    case @battle.field.terrain
      when PBBattleTerrains::Electric
        @battle.pbDisplay(_INTL("The electric current disappeared from the battlefield!"))
      when PBBattleTerrains::Grassy
        @battle.pbDisplay(_INTL("The grass disappeared from the battlefield!"))
      when PBBattleTerrains::Misty
        @battle.pbDisplay(_INTL("The mist disappeared from the battlefield!"))
      when PBBattleTerrains::Psychic
        @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield!"))
    end
    @battle.field.terrain = PBBattleTerrains::None
  end
end

#===============================================================================
# Corrosive Gas
#===============================================================================
class PokeBattle_Move_221 < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    return if @battle.wildBattle? && user.opposes?   # Wild Pokémon can't knock off
    return if user.fainted?
    return if target.damageState.substitute
    return if target.item==0 || target.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
    itemName = target.itemName
    target.pbRemoveItem(false)
    @battle.pbDisplay(_INTL("{1} corroded {2}'s {3}!",user.pbThis,target.pbThis,itemName))
  end
end

#===============================================================================
# Lash Out
#===============================================================================
class PokeBattle_Move_222 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if user.effects[PBEffects::LashOut]
    p "proc" if user.effects[PBEffects::LashOut]
    return baseDmg
  end
end

#===============================================================================
# Burns opposing Pokemon that have increased their stats in that turn before the
# execution of this move (Burning Jealousy)
#===============================================================================
 class PokeBattle_Move_223 < PokeBattle_Move
   def pbAdditionalEffect(user,target)
     return if target.damageState.substitute
     if target.pbCanBurn?(user,false,self) && 
        target.effects[PBEffects::BurningJealousy]
       target.pbBurn(user)
     end
   end
 end