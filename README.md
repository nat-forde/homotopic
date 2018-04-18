#homotopic

Work by edickie and nforde

Project is heavily based on the Shen 2015 paper:
Shen K, Mišić B, Cipollini BN, et al (2015) 
Stable long-range interhemispheric coordination is supported by direct anatomical projections. Proc Natl Acad Sci 112:6473–6478.

ROIs are classified as intrahemispheric, heterotopic or homotopic 

Atlases: 
originally used aparc
now using Glasser's MMP
potentially Shen at various parcellations

Dataset:
POND 
ABIDE

################ P1. Functional stuff ##############################
Calculates the functional connectivity strength and stability between ROIs

Scripts:
> extract_rs_time_series.sh - generates resting state times series csv's 
> temp_stab_glasser.r - calculates FC temporal stability 
	> qbatch_mk_sub.sh - wrapper to submit temp_stab_glasser.r to the local queue
> strength_calc_glasser.Rmd - calculates FC strength and does stats
> temporal_stability_calc_glasser.Rmd - calculates temp stability and does stats (reads in already calculated TS if available [reccommended to do in separte steps using the cluster to generate the TS first])


############# P2. Diffusion stuff ######################################
Uses MRtrix to do tractography and generate connectivity matrices

Scripts:
> CSD.sh - basic script to do tractography and generate matrices locally
> CSD_scc.sh - same as above but adapted for use on the SCC
	> CSD_qbatch_wrap.sh - wrapper to submit to the SCC
> CSD_scc_prob.sh - same as above but for probabilistic instead of deterministic tractography
> diffusion_glasser.Rmd - analyses of diffusion data by type (intrahemispheric, heterotopic, homotopic) and length qunatile
 

others:
> gmwmi_voxel_count.sh - extracts the number of voxels along the gm wm interface within each ROI to later correct connectivity matrices by (incorporated into CSD scripts)
> tck2trk.py - changes streamline file type
	> tck2trk_loop.sh - wrapper


############## P3. Function & Structure ###############################
Combines the functional and structural analyses from above

Scripts:
> func_struct.Rmd - calculates and analyses FC strength, temporal stability and diffusion together (by type, length quantile and diffusion weighted quantile)


############### P4. Graph theory #####################################
Graph theory.....

Scripts:
> graphs.Rmd - extracts matrices for each metric
> graph_bct.m - calculates network measures from FC and diffusion graphs


