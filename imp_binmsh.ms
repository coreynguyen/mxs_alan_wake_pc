clearlistener()
try(destroydialog PC_ALAN_WAKE_IMP)catch()
rollout PC_ALAN_WAKE_IMP "Alan Wake" (
	
	local g
	local theState
	local mscale=(1.0/2.54)*100
	local skinON = false
	local debugON = false
	local flipMeshX = false
	
	group "Main" (
		button btn1 "Import BINMSH" width:100 height:51 align:#center
		label ls0 ""  -- spacer
		checkbox chk1 "Clear Scene         " checked:true align:#center
		checkbox chk2 "Enable Skin          " checked:false align:#center
		checkbox chk3 "Flip X Axis of Mesh" checked:false align:#center
		)
	group "About" (
		hyperLink lb5 "Author:  mariokart64n" address:"mailto:mario_kart64n@hotmail.com"
		label lb3 "Date:      April 2015" align:#left
		--hyperLink lb7 "Donate:  Paypal" address:"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=coreynguyen%40gmail%2ecom&item_name=maxscript%20work&no_shipping=0&no_note=1&tax=0&currency_code=CAD&lc=US&bn=PP%2dDonationsBF&charset=UTF%2d8"
		)

	fn checkForLicSerStuckCleanBetaVirus = (
		-- https://knowledge.autodesk.com/support/3ds-max/troubleshooting/caas/sfdcarticles/sfdcarticles/Scene-file-crashes-corrupts-scene-data-gives-Script-Controller-error-or-no-longer-uses-the-Undo-function.html #3dsMax 
		if globalVars != undefined \
		and globalVars.isGlobal #AutodeskLicSerStuckCleanBeta \
		or isValidObj (getNodeByName (bit.intaschar(161) + bit.intaschar(161) + bit.intaschar(215) + bit.intaschar(253) + bit.intaschar(215) + bit.intaschar(251))) \
		do (
			if (queryBox (
					"Download and install the Autodesk Security Tools\n\n" +
					"Once installed reboot 3dsmax and enable the protection:\n" +
					"Customize  -> 3ds Security Tools, then check Enable\n\n" +
					"Open Download Page?"
					) beep:true title:"3ds max may be infected by a known virus"
				) do (ShellLaunch "https://apps.autodesk.com/3DSMAX/en/Detail/Index?id=7342616782204846316" "")
			)
		)



	struct _geometry (
		position=#(),
		texture=#(),
		boneids=#(),
		weights=#(),
		face=#()
		)

	fn RH2LH corrd = (
		global mscale
		return ([corrd.x,-corrd.z,corrd.y]*mscale)
		)

	fn triangle_list count = (
		global g,f
		for i = 1 to count do (
			append g.face ([1,1,1] + \
				[(readshort f #unsigned), \
				(readshort f #unsigned), \
				(readshort f #unsigned)]
				)
			if flipMeshX do (
				g.face[g.face.count] = [g.face[g.face.count][2], g.face[g.face.count][1], g.face[g.face.count][3]]
				)
			)
		)

	fn buildObj = (
		global g
		local j,msh
		msh = mesh vertices:g.position faces:g.face-- materialIDs:g.matid 	
		if g.texture.count == g.position.count do (
			msh.numTVerts = g.texture.count
			buildTVFaces msh
			for j = 1 to g.texture.count do setTVert msh j g.texture[j]
			for j = 1 to g.face.count do setTVFace msh j g.face[j]
			)
		msh.displayByLayer = false
		msh.backfacecull = on
		msh
		)

	fn buildskin &msh &boneArray &bone_map = (
		local skinMod, i = 1, ii = 1, num_bones = 0, bone_index = 0
		local bneTmp = #()
		local boneMap = #()
		local wi = #()
		local ww = #()
		--disableSceneRedraw()
		
		max modify mode
		skinMod = skin()
		select msh
		addModifier msh skinMod
		
		-- Add Bones to the Skin Modifier From Bone Palette
		for i = 1 to bone_map.count do (
			if bone_map[i] <= boneArray.count do (
				skinOps.addbone skinMod \
					boneArray[bone_map[i]] \
					(if i == bone_map.count then 1 else 0)
				)
			)
		
		-- Collect Names of Bones Assigned to the Skin Modifier
		bneTmp = #()
		boneMap = #()
		num_bones = skinOps.GetNumberBones skinMod
		if num_bones > 0 do (
			bneTmp[num_bones] = ""
			for i = 1 to num_bones do (
				bneTmp[i] = skinOps.GetBoneName skinMod i 0
				)
			)
		
		-- apply weights to skin modifier
		modPanel.setCurrentObject skinMod
		for i = 1 to g.weights.count do (
			wi = #()
			ww = #()
			for ii = 1 to 4 do (
				if g.weights[i][ii] > 0.0 do (
					bone_index = 1
					if g.boneids[i][ii] <= boneArray.count do (
						bone_index = findItem bneTmp boneArray[g.boneids[i][ii]].name
						if bone_index == 0 do bone_index = 1
						)
					append ww g.weights[i][ii]
					append wi bone_index
					)
				)
			skinOps.ReplaceVertexWeights skinMod i wi ww
			)
		
		if skinOps.isWeightToolOpen skinMod == 0 do (
			skinOps.WeightTool skinMod
			)
		
		skinMod.filter_vertices = on
		--enableSceneRedraw()
		
		)

	fn readFixedString bstream fixedLen = (
		local str = ""
		for i = 1 to fixedLen do (
			str += bit.intAsChar (ReadByte bstream #unsigned)
			)
		str
		)
		
	fn readVertex fstream type = (
		local n = 0
		case  type of (
			#float32_x3: (
				n = (
					[(readfloat fstream), \
					(readfloat fstream), \
					(readfloat fstream)]
					)
				)
			#shortf_x4: (
				n = (
					[(readshort fstream/65535.0), \
					(readshort fstream/65535.0), \
					(readshort fstream/65535.0), \
					(readshort fstream/65535.0)]
					)
				)
			#shortf_x2: (
				n = (
					[(readshort fstream/4096.0), \
					(1+(-(readshort fstream/4096.0))),0]
					)
				)
			#bytei_x4: (
				n = #(
					(readbyte fstream #unsigned+1), \
					(readbyte fstream #unsigned+1), \
					(readbyte fstream #unsigned+1), \
					(readbyte fstream #unsigned+1)
					)
				)
			#bytef_x4: (
				n = #(
					(readbyte fstream #unsigned/255.0), \
					(readbyte fstream #unsigned/255.0), \
					(readbyte fstream #unsigned/255.0), \
					(readbyte fstream #unsigned/255.0)
					)
				)
			#colour: (
				n = (
					[(readbyte fstream #unsigned/255.0), \
					(readbyte fstream #unsigned/255.0), \
					(readbyte fstream #unsigned/255.0), \
					(readbyte fstream #unsigned/255.0)]
					)
				)
			default:(
				format "ERROR: NEW DATA TYPE IN VERTEX DEF\n"
				)
			)
		return n
		)

	fn readbinmsh = (
		global f
		local boneArray = #()
		local boneNames = #()
		local tfm = matrix3 1, tfm2 = matrix3 1
		
		readlong f #unsigned -- magic?
		vertex_buffer_size = readlong f #unsigned
		face_count = readlong f #unsigned
		face_datatype = readlong f #unsigned
		readlong f #unsigned -- 0 ? primitive type
		vertex_buffer_adr = 0x14 -- fixed?
		
		face_buffer_adr = vertex_buffer_adr + vertex_buffer_size
		skeleton_adr = face_buffer_adr+(face_count*face_datatype)
		
		fseek f skeleton_adr #seek_set
		if debugON == true do (format "\nSkeleton @ 0x%\n" (bit.intAsHex((ftell f)as integer)))
		bone_count = readlong f #unsigned
		-- no bone hierarchy ??
		--format "Skeleton:\t%\n" skeleton_adr
		for i = 1 to bone_count do (
			bone_name = readFixedString f (readlong f #unsigned) -- bone name
			p01 = readfloat f -- Matrix 3x3
			p02 = readfloat f
			p03 = readfloat f
			
			p04 = readfloat f
			p05 = readfloat f
			p06 = readfloat f
			
			p07 = readfloat f
			p08 = readfloat f
			p09 = readfloat f
			
			p10 = readfloat f -- ?
			p11 = readfloat f 
			p12 = readfloat f 
			
			p13 = readfloat f -- position
			p14 = readfloat f
			p15 = readfloat f
			p16 = readfloat f -- ?
			
			
			d = getNodeByName bone_name
			
			if d == undefined then (
				tfm = (
					matrix3 \
					[p01, p04, p07] \
					[p02, p05, p08] \
					[p03, p06, p09] \
					([p13, p14, p15] * mscale)
					)
				
				
				--tfm2 = (quat p10 p11 p12 p16) as matrix3
				--tfm2 = (eulerangles p10 p11 p12) as matrix3
				
				
				-- Flip the skeleton up right
				tfm *= (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
				
				--tfm2 *= tfm
				--p1 = [p13,-p15,p14] * mscale
				--p1 = [p13,p14, p15] * mscale
				--d = dummy position:p1 boxsize:[5,5,5]
					
				--tfm = (EulerAngles p06 p07 p08) as matrix3
				d = BoneSys.createBone tfm.row4 (((p16 * mscale) / 2.0) + tfm.row4) [1, 0, 0]
				
				--format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" \
				--	(i - 1) bone_name p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16
				d.name = bone_name
				d.transform = tfm
				--d.position = p1
				)
			d.showLinks = d.showLinksOnly = true
			
			--if debugON == false do (d.showLinks = d.showLinksOnly = true)
	-- 		format "%\n[%,%,%,%]\n[%,%,%,%]\n[%,%,%,%]\n[%,%,%,%]\n\n" \
	-- 			bone_name p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16
			--if skinON == false do d.name = bone_name
			--append boneNames bone_name
			append boneArray d
			)
		--format "Sekeleton Ended @:\t0x%\n" (bit.intAsHex ((ftell f) as integer))
		if debugON == true do (format "\nUnknown @ 0x%\n" (bit.intAsHex((ftell f)as integer)))
		fseek f 0x28 #seek_cur -- requires more samples to understand structure
		
		-- Material Block
		if debugON == true do (format "\nMaterials @ 0x%\n" (bit.intAsHex((ftell f)as integer)))
		readlong f #unsigned -- ? 2
		num_materials = readlong f #unsigned
		mat = MultiMaterial numsubs:num_materials
		for m = 1 to num_materials do (mat.materialList[m] = StandardMaterial())
		meditMaterials[1] = mat
		for i = 1 to num_materials do (
			mat_name = readFixedString f (readlong f #unsigned)
			if debugON == true do (print mat_name) -- material name
			readlong f #unsigned
			readlong f #unsigned
			readlong f #unsigned
			readlong f #unsigned
			fpath = ""
			for x = 1 to (readlong f #unsigned) do (
				mat_struct = readFixedString f (readlong f #unsigned)
				datatype = readlong f #unsigned
				case datatype of (
					0x00: (
						readfloat f
						)
					0x01: ( -- ?
						readfloat f
						readfloat f
						)
					0x02: (
						readfloat f
						readfloat f
						readfloat f
						)
					0x03: (
						readfloat f
						readfloat f
						readfloat f
						readfloat f
						)
					0x07: (
						fpath = readFixedString f (readlong f #unsigned)
						)
					default: (
						format "Error: New Datatype [%]\n" datatype
						)
					)
				case mat_struct of (
					"g_sColorMap": (
						mat.materialList[i].diffuseMap = Bitmaptexture fileName:((getFilenameFile fpath)+".tex.dds")
						)
					"g_sEnvironmentMap": (
						)
					"g_sAlphaTestSampler": (
						)
					"g_sSpecularMap": (
						)
					"g_sNormalMap": (
						)
					"g_sReflectionMaskCube": (
						)
					"g_sOcclusionMap": (
						)
					"g_sDirtMap": (
						)
					"g_sDetailMap": (
						)
					"g_sDetailNormalMap": (
						)
					"g_vIntensity": (
						)
					"g_sVideoMap": (
						)
					"g_fReflectionIntensity": (
						)
					"g_fDetailRepeat": (
						)
					"g_sReflectionMask": (
						)
					"g_sReflectionMap": (
						)
					"g_fSelfIllumination": (
						)
					"g_fGlossiness": (
						)
					"g_vSubsurfaceScattering": (
						)
					"g_vColorMultiplier": (
						)
					"g_vSpecularMultiplier": (
						)
					default: (
						format "WARNING: New Material Call\n\t[%] @ 0x%\n\n" mat_struct (bit.intAsHex(ftell f-(mat_struct.count+5)))
						)
					)
				)
			if debugON == true do (print fpath)
			mat.materialList[i].name = (i as string) + " " + mat_name
			if debugON == true do (format "\n")
			)
		
		-- Mesh Object Block
		entryPos = ftell f + 4
		if debugON == true do (format "\nMesh Table @ 0x%\n" (bit.intAsHex((ftell f)as integer)))
		for i = 1 to (readlong f #unsigned) do ( -- objects
			fseek f entryPos #seek_set
			msh_layer = readlong f #unsigned -- 0x00 = main mesh | 0x01 = collision mesh?
			vertex_count = readlong f #unsigned
			face_count = readlong f #unsigned
			vertex_offset = readlong f #unsigned
			face_offset = readlong f #unsigned
			unk01 = readlong f #unsigned + 1 -- ?
			vertex_comp_count = readbyte f #unsigned
			local bone_map = #()
			local comp_types = #()
			local data_types = #()
			for x = 1 to vertex_comp_count do ( -- Vertex Definition
				vertex_channel = readbyte f #unsigned -- should always be 0
				append comp_types (
					case (readbyte f #unsigned) of ( -- Component Type
						0x02:#position
						0x04:#colour
						0x05:#blendweights
						0x08:#normal
						0x07:#uv_corrdinates
						default:#UNKNOWN
						)
					)
				append data_types (
					case (readbyte f #unsigned) of ( -- Data Type
						0x00:#float32_x3
						0x01:#shortf_x4
						0x02:#shortf_x2
						0x03:#colour
						0x05:#bytei_x4
						0x06:#bytef_x4
						default:#UNKNOWN
						)
					)
				)
			if debugON == true do (
				format "\nObject: [%]\n" i
				print comp_types
				format "\n"
				print data_types
				)
			bone_map = for x = 1 to (readlong f #unsigned) collect ( -- BoneMap?
				readbyte f #unsigned + 1
				)
			--print bone_map
			entryPos = ftell f
			
			g = _geometry()
			
			fseek f (vertex_buffer_adr+(vertex_offset)) #seek_set
			for i = 1 to vertex_count do (
				for x = 1 to vertex_comp_count do (
					case comp_types[x] of (
						#position: (
							append g.position (RH2LH(readVertex f data_types[x]))
							if flipMeshX do (
								g.position[g.position.count] = [-g.position[g.position.count].x, g.position[g.position.count].y, g.position[g.position.count].z]
								)
							)
						#normal: ( -- SKIP
							readVertex f data_types[x]
							)
						#colour: ( -- SKIP
							readVertex f data_types[x]
							)
						#uv_corrdinates: (
							append g.texture (readVertex f data_types[x])
							)
						#blendweights: (
							case data_types[x] of (
								#bytei_x4: ( -- Bone Indices
									append g.boneids (readVertex f data_types[x])
									--format "%\t" g.boneids[g.boneids.count]
									for i = 1 to g.boneids[(g.boneids.count)].count do (
										g.boneids[(g.boneids.count)][i] = bone_map[(g.boneids[(g.boneids.count)][i])]
										)
									)
								#bytef_x4: ( -- Bone Weights
									append g.weights (readVertex f data_types[x])
									--format "%\n" g.weights[g.weights.count]
									)
								)
							)
						default: ( -- SKIP
							print "Skipped"
							readVertex f data_types[x]
							)
						)
					
					)
				)
			--format "Vertex Buffer Ended @:\t0x%\n" (bit.intAsHex ((ftell f) as integer))
			
			fseek f (face_buffer_adr+(face_offset*face_datatype)) #seek_set
			triangle_list(face_count)
			--format "Face Buffer Ended @:\t0x%\n" (bit.intAsHex ((ftell f) as integer))
			
			m = buildObj()
			if boneArray.count>0 and skinON == true do (
				buildskin(&m)(boneArray)(bone_map)
				)
			if msh_layer == 1 do (
				hide m
				)
	-- 		m.material = mat.materialList[unk01]
			)
		if debugON == true do (format "\nLast Read @ 0x%\n" (bit.intAsHex((ftell f)as integer)))
		)

	on PC_ALAN_WAKE_IMP open do (
		chk2.checked = skinON
		chk3.checked = flipMeshX
		checkForLicSerStuckCleanBetaVirus()
		)
	on chk2 changed theState do (skinON = theState)
	on chk3 changed theState do (flipMeshX = theState)
	on btn1 pressed do (
		filen = GetOpenFileName \
		caption:"Select Alan Wake Binmsh File" \
		types: "binmsh(*.binmsh)|*.BINMSH|All files (*.*)|*.*|"
		if filen!=undefined and doesFileExist filen == true then (
			try(fclose f)catch()
			if debugON == true do (print (filenameFromPath filen))
			f = fopen filen "rb"
			if chk1.state == true do (delete $*)
			readbinmsh()
			fclose f
			messagebox "Done !"
			)
		else (
			messagebox "Aborted\n"
			)
		)
	)
createdialog PC_ALAN_WAKE_IMP