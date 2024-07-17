function pol2grp (data, nch)

% Bradley White
% 2024 February
% MATLAB R2014b

% INPUTS
% data   = '/home/brad/Documents/MATLAB/anat/level2/';
%          uigetdir does not have the trailing '/', so if you want to use
%          that, you must change some path strings below.
% nch    = 44; % number of channels, e.g., 44

% load poi libraries for xlwrite on linux
javaaddpath('anat/xlwrite/poi_library/poi-3.8-20120326.jar');
javaaddpath('anat/xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
javaaddpath('anat/xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
javaaddpath('anat/xlwrite/poi_library/xmlbeans-2.3.0.jar');
javaaddpath('anat/xlwrite/poi_library/dom4j-1.6.1.jar');
javaaddpath('anat/xlwrite/poi_library/stax-api-1.0.1.jar');

% load paths
subs = dir([data, 'sub-*']); subs = {subs.name}';
mats = cell(length(subs),1); for i = 1:length(subs); mats{i} = fullfile(data, subs{i}, [subs{i}, '_est.mat']); end
mkdir([data, 'group']);

% convert to xls and group for ReadM
for ii = 1:length(subs)
    load(mats{ii});
    writedat(data, subs{ii}, affineEstData);
end

[HATtC, SDtC] = ReadingM_brad([data,'group/']);
xlwrite([data, 'group/group_est.xls'], [HATtC,SDtC], 'group');

chs = HATtC((length(HATtC)-nch+1):end, 1:3);
sds = SDtC((length(SDtC)-nch+1):end, 1);
vas = sds; max = ['E' num2str(nch+1)]; min = ['E' num2str(nch+2)]; rng = [15;0];
xlwrite([data, 'group/group_plt.xls'], [chs,sds,vas]);
xlwrite([data, 'group/group_plt.xls'], rng, [max ':' min]);

% Perform Anatomical Labeling and Save
nfri_anatomlabel_brad(HATtC((length(HATtC)-nch+1):end, 1:3), [data, 'group/group_ba10'], 10, 5); % 10 mm, BA
ch_MNI_mm = ones(4, nch); ch_MNI_mm(1:3,:) = (HATtC((length(HATtC)-nch+1):end, 1:3))';

% Convert to SPM Template (Voxels)
template_info = spm_vol([spm('dir') filesep 'templates' filesep 'T1.nii']);
ch_MNI_vx = inv(template_info.mat) * ch_MNI_mm;
[rend, rendered_MNI] = render_MNI_coordinates(ch_MNI_vx, template_info);
for kk = 1:6
    rendered_MNI{kk}.ren = rend{kk}.ren;
end

% Render MNI on SPM Template and save
h = NIRS_Rendered_MNI_Viewer(rendered_MNI);
print(h, [data, 'group/group_mni.tif'],'-dtiff', '-r300');

% Render with channel numbers
f = NIRS_RegistrationResult_Viewer_brad(rendered_MNI, 3); % right view
print(f, [data, 'group/group_right.tif'],'-dtiff', '-r300');

g = NIRS_RegistrationResult_Viewer_brad(rendered_MNI, 4); % left view
print(g, [data, 'group/group_left.tif'],'-dtiff', '-r300');

% Render with standard deviations
nfri_mni_plot('jet', [data, 'group/group_plt.xls']);

end

function writedat(data, sub, affineEstData)
    warning off all;
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.OtherH, 'WShatH'); % given head surface points
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.OtherC, 'WShatC'); % % given cortical surface points
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.OtherHSD, 'WS_SDH'); % transformation SD for given head surface points
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.OtherCSD, 'WS_SDC');% transformation SD for given cortical surface points
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.SSwsH, 'SSwsH');
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.SSwsC, 'SSwsC');
    
    TextA = cell(1); TextA{1} = 'Reference brain number';
    xlwrite([data, 'group/', [sub, '_est.xls']], TextA, 'Info', 'A1');
    xlwrite([data, 'group/', [sub, '_est.xls']], affineEstData.RefN, 'Info', 'A2');
    
    TextB = cell(1); TextB{1} = 'Reference points used';
    xlwrite([data, 'group/', [sub, '_est.xls']], TextB, 'Info', 'A3');
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
