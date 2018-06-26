sand_king_burrowstrike_lua = class({})
LinkLuaModifier( "modifier_sand_king_burrowstrike_lua", "lua_abilities/sand_king_burrowstrike_lua/modifier_sand_king_burrowstrike_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_stunned_lua", "lua_abilities/generic/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- function sand_king_burrowstrike_lua:GetCooldown( level )
-- 	if self:GetCaster():HasScepter() then
-- 		return self:GetSpecialValueFor( "cooldown_scepter" )
-- 	end

-- 	return self.BaseClass.GetCooldown( self, level )
-- end

--------------------------------------------------------------------------------
-- Ability Start
function sand_king_burrowstrike_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()
	if target then point = target:GetOrigin() end
	local origin = caster:GetOrigin()

	-- load data
	local anim_time = self:GetSpecialValueFor("burrow_anim_time")

	-- projectile data
	local projectile_name = ""
	local projectile_start_radius = self:GetSpecialValueFor("burrow_width")
	local projectile_end_radius = projectile_start_radius
	local projectile_direction = (point-origin)
	projectile_direction.z = 0
	projectile_direction:Normalized()
	local projectile_speed = self:GetSpecialValueFor("burrow_speed")
	local projectile_distance = (point-origin):Length2D()

	-- create projectile
	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		
	    bDeleteOnHit = false,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	    
	    EffectName = projectile_name,
	    fDistance = projectile_distance,
	    fStartRadius = projectile_start_radius,
	    fEndRadius =projectile_end_radius,
		vVelocity = projectile_direction * projectile_speed,
	}
	ProjectileManager:CreateLinearProjectile(info)

	-- add modifier to caster
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_sand_king_burrowstrike_lua", -- modifier name
		{ 
			duration = anim_time,
			pos_x = point.x,
			pos_y = point.y,
			pos_z = point.z,
		} -- kv
	)
end
--------------------------------------------------------------------------------
-- Projectile
function sand_king_burrowstrike_lua:OnProjectileHit( target, location )
	if not target then return end

	-- cancel if linken
	if target:TriggerSpellAbsorb( self ) then return end

	-- apply stun
	local duration = self:GetSpecialValueFor( "burrow_duration" )
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self, -- ability source
		"modifier_generic_stunned_lua", -- modifier name
		{ duration = duration } -- kv
	)

	-- apply damage
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = self:GetAbilityDamage(),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)
end

--------------------------------------------------------------------------------
function sand_king_burrowstrike_lua:PlayEffects()
	-- Get Resources
	local particle_cast = "string"
	local sound_cast = "string"

	-- Get Data

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_NAME, hOwner )
	ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		iControlPoint,
		hTarget,
		PATTACH_NAME,
		"attach_name",
		vOrigin, -- unknown
		bool -- unknown, true
	)
	ParticleManager:SetParticleControlForward( effect_cast, iControlPoint, vForward )
	SetParticleControlOrientation( effect_cast, iControlPoint, vForward, vRight, vUp )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( vTargetPosition, sound_location, self:GetCaster() )
	EmitSoundOn( sound_target, target )
end