const vec2 blurOffsets[32] = vec2[32](
   vec2(0.12064426510477419, 0.015554431411765695),
   vec2(-0.16400077998918963, 0.16180237012184204),
   vec2(0.020080498035937415, -0.2628838391620438),
   vec2(0.19686650437195816, 0.27801320993574674),
   vec2(-0.37362329188851157, -0.049763799980476156),
   vec2(0.34544673107582735, -0.20696126421568928),
   vec2(-0.12135781397691386, 0.4507963336805642),
   vec2(-0.22749138875333694, -0.41407969197383454),
   vec2(0.4797593802468298, 0.19235249500691445),
   vec2(-0.5079968434096749, 0.22345015963708734),
   vec2(0.23843255951864029, -0.5032700515259672),
   vec2(0.17505863904522073, 0.587555727235086),
   vec2(-0.5451127409909945, -0.2978253068585009),
   vec2(0.6300137885218894, -0.12390992876509886),
   vec2(-0.391501580064061, 0.5662295575692019),
   vec2(-0.09379538975841809, -0.6746452122696498),
   vec2(0.5447160222309757, 0.47831268960533435),
   vec2(-0.7432342062047558, 0.046109375942755174),
   vec2(0.5345993903170301, -0.520777903066999),
   vec2(-0.0404139208253129, 0.7953459466435174),
   vec2(-0.517173266802963, -0.5989723613060595),
   vec2(0.8080038585189984, 0.12485626574164435),
   vec2(-0.6926663754026566, 0.494463047083117),
   vec2(0.183730322451809, -0.8205069509230769),
   vec2(0.43067753069940745, 0.7747454863024757),
   vec2(-0.8548041452377114, -0.25576180722119723),
   vec2(0.8217466662308877, -0.3661258311820314),
   vec2(-0.36224393661662146, 0.87070999332353),
   vec2(-0.32376306917956177, -0.8724793262829371),
   vec2(0.8455529005007657, 0.4622425905108438),
   vec2(-0.9483903811252437, 0.2643989345002705),
   vec2(0.5322400733549763, -0.818975339518135)
);

vec3 getBlur(vec3 color, vec3 viewPos) {
	vec3 blur = vec3(0.0);
	
    float z0 = texture2D(depthtex1, texCoord).x;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float coc = 0.0;

	#ifdef DOF
	coc = max(abs(z0 - centerDepthSmooth) * DOF_STRENGTH - 0.01, 0.0);
	coc = coc / sqrt(coc * coc + 0.1);
	#endif

	#ifdef DISTANT_BLUR
	coc = min(length(viewPos) * DISTANT_BLUR_RANGE * 0.00025, DISTANT_BLUR_STRENGTH * 0.025) * DISTANT_BLUR_STRENGTH;
	#endif

    float lod = log2(viewHeight * aspectRatio * coc * fovScale / 320.0);
	
	if (coc > 0.0 && z0 > 0.56) {
		for(int i = 0; i < 32; i++) {
			vec2 offset = blurOffsets[i] * coc * 0.025 * fovScale * vec2(1.0 / aspectRatio, 1.0);
			blur += texture2DLod(colortex0, texCoord + offset, lod).rgb;
		}
		blur /= 32.0;
	}

	else blur = color;
	return blur;
}