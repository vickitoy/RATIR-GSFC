;+
; NAME:
;	autopipeskysub
;
; PURPOSE:
;	Flatten data using sky flat with matching filter name.  (subfunction subtracts sky flat from data 
;	and then subtracts median of that from remaining data.  Adds 1000 offset afterwards.  
;	Then crops and saves new fits file. <- manual crop)
;
; OPTIONAL KEYWORDS:
;	outpipevar - output pipeline parameters
;	inpipevar  - input pipeline parameters (typically set in autopipedefaults.pro or ratautoproc.pro, but can be set to default) 
;
; EXAMPLE:
;	autopipeskysub, outpipevar, inpipevar=pipevar
;
; DEPENDENCIES:
;	skypipeproc (RATIR specific crop)
;
; Written by Dan Perley 
; Modified by Vicki Toy 11/18/2013
;
; FUTURE IMPROVEMENTS:
;	prefchar in variable structure? in skypipeproc crops to hand chosen RATIR size (different
;	for optical and infrared), automate cropping (MUST CHANGE FOR RIMAS)? 
;	1000 offset after subtraction necessary?
;-

pro autopipeskysub, outpipevar=outpipevar, inpipevar=inpipevar

	;Setup pipeline variables that carry throughout the pipeline
	if keyword_set(inpipevar) then begin
		pipevar = inpipevar
		print, 'Using provided pipevar'
	endif else begin
		pipevar = {autoastrocommand:'autoastrometry' , sexcommand:'sex' , swarpcommand:'swarp' , $
					datadir:'' , imworkingdir:'' , overwrite:0 , modestr:'',$
					flatfail:'' , catastrofail:'' , relastrofail:'' , fullastrofail:'' , $
					pipeautopath:'' , refdatapath:'', defaultspath:'' }
	endelse

	;CHANGE FOR RIMAS VLT
   	prefchar = '2'

	print, pipevar.imworkingdir

	;Find data that needs to be sky subtracted
   	files = findfile(pipevar.imworkingdir+'fp'+prefchar+'*img*.fits')
   	sfiles = findfile(pipevar.imworkingdir+'sfp'+prefchar+'*img*.fits')
   	if n_elements(files) eq 1 and files[0] eq '' then return

   	
   	;Find sky files made in autopipemakesky.pro
   	skys = findfile(pipevar.imworkingdir+'*sky-*.fits')
   	
   	;Find the associated filter with each combined sky fits file
   	skyfilts = strarr(n_elements(skys))

   	if skys[0] ne '' then begin
     	for f = 0, n_elements(skys)-1 do begin
       		h = headfits(skys[f], /silent)
       		filter = clip(sxpar(h, 'FILTER'))
       		skyfilts[f] = filter
     	endfor
   	endif else begin
     	print, 'No combined sky files found, cannot sky subtract'
     	return
   	endelse
   
   	;For each fits file if output files don't exist or override set then read file header
   	;and see if have skyflat for desired filter, sky subtract if it exists using skypipeproc
   	for f = 0, n_elements(files)-1 do begin
   	
      	if files[f] eq '' then continue	
      	outfile = fileappend(files[f], 's')
      	match = where(outfile eq sfiles, ct)
      	
      	if ct eq 0 or pipevar.overwrite then begin               
         	h = headfits(files[f], /silent)
         	camera = sxpar(h,'WAVELENG')
         	camera = strcompress(camera,/remove_all)

         	filter = clip(sxpar(h, 'FILTER'))
         	skyfileno = where(skyfilts eq filter, ct)
         	
			;If file does not have a matching processed sky file for the filter put in flatfail variable
        	if ct eq 0 then begin
            	skyfilenoothbin = where(skyfilts eq filter,ctwobin)
            	print, 'Sky field not found for '
            	print, removerpath(files[f])
            	flatfail = [flatfail, files[f]]
            	continue
         	endif
         
         	;If file has matching processed sky file then run skypipeproc RATIR specific crop CHANGE FOR RIMAS VLT
         	;This creates new sky subtracted fits file
         	skyfile = skys[skyfileno[0]]
         	print, 'Sky Subtracting ', removepath(files[f]), ' using ', removepath(skyfile)
         	skypipeproc, files[f], skyfile

      	endif
	endfor
	
	outpipevar = pipevar
end