function pol2mni(origin, others, nch)

% Bradley White
% 2024 February
% MATLAB R2014b

% INPUTS
% origin     path to csv file with 10-20 fiducial polhemus measurements
% others     path to csv file with s-d-c polhemus measurements
% nch        number of channels in probe array

% origin = '/home/brad/Documents/MATLAB/anat/level1/sub-000/sub-000_origin.csv';
% others = '/home/brad/Documents/MATLAB/anat/level1/sub-000/sub-000_others.csv';
% nch=50;

% origin = '/home/brad/Documents/MATLAB/anat/level1/sub-033/sub-033_origin.csv';
% others = '/home/brad/Documents/MATLAB/anat/level1/sub-033/sub-033_others.csv';
% nch=44;

% Paths
[pn, sub] = fileparts(fileparts(origin));

% Run Affine Estimation and Save
affineEstData = nfri_mni_estimation_brad(origin, others);
save([pn, filesep, sub, filesep, sub, '_est.mat'], 'affineEstData');

% Perform Anatomical Labeling and Save
WShatC = affineEstData.OtherC;
ch_MNI_mm = ones(4, nch); ch_MNI_mm(1:3,:) = (WShatC((length(WShatC)-nch+1):end, 1:3))';
%nfri_anatomlabel_brad(WShatC((length(WShatC)-nch+1):end, 1:3), [pn, filesep, sub, filesep, sub, '_aal-10'], 10, 4); % 10 mm, AAL
nfri_anatomlabel_brad(WShatC((length(WShatC)-nch+1):end, 1:3), [pn, filesep, sub, filesep, sub, '_bar-10'], 10, 5); % 10 mm, BAR
%nfri_anatomlabel_brad(WShatC((length(WShatC)-nch+1):end, 1:3), [pn, filesep, sub, filesep, sub, '_lpb-10'], 10, 6); % 10 mm, LPB
%nfri_anatomlabel_brad(WShatC((length(WShatC)-nch+1):end, 1:3), [pn, filesep, sub, filesep, sub, '_bat-10'], 10, 7); % 10 mm, BAT

% Convert to SPM Template (Voxels)
template_info = spm_vol([spm('dir') filesep 'templates' filesep 'T1.nii']);
ch_MNI_vx = inv(template_info.mat) * ch_MNI_mm;
[rend, rendered_MNI] = render_MNI_coordinates(ch_MNI_vx, template_info);
for kk = 1:6
    rendered_MNI{kk}.ren = rend{kk}.ren;
end

% Render MNI on SPM Template and Save
h = NIRS_Rendered_MNI_Viewer(rendered_MNI);
print(h, [pn, filesep, sub, filesep, sub, '_mni1.tif'],'-dtiff', '-r300'); % manually set for each view

end

% ---------------------------
% Variable information
% ---------------------------

% W:
%  affine-transformation matrix.
%
% OtherH:
%  given head surface points transformed to the MNI(WS hat).
%
% OtherC:
%  given cortical surface points transformed to the MNI(WS hat).
%
% OtherHMean:
%  an average of given head surface points transformed to the MNI ideal head (within-subject mean).
%
% OtherCMean:
%  an average of given cortical surface points transformed to the MNI ideal brain (within-subject mean).
%
% PListOverPoint:
%  given head surface points transformed to the MNI reference heads, point manner.
%
% CPListOverPoint:
%  given cortical porojection points transformed to the MNI reference brains, point manner.

% OtherRefList or OtherRefList{:} to get given head surface points transformed to the MNI reference heads, reference head manner.
% OtherRefCList or OtherRefCList{:} to get given cortical porojection points transformed to the MNI reference brains, reference brain manner.

% OtherHVar to get transformation variances for given head surface points, point manner.
% OtherCVar to get transformation variances for given cortical surface points, point manner.
% In either variance, the first three values indicate x, y, z variances and 4th value, composite variance,r^2.

% OtherHSD to get transformation SD for given head surface points, point manner.
% OtherCSD to get transformation SD for given cortical surface points, point manner.
% In either SDC, the first three values indicate x, y, z SDs and 4th value, composite SD of r.
