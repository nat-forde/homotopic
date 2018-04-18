close all;
clear all;
clc;

%%
cd /mnt/tigrlab/scratch/nforde/homotopic/POND/CSD
%subs = textread('sub_list.txt', '%s', 'delimiter', '\n');
subs = dir('MR*');

out = zeros(length(subs),9);

%%
%for i=1:length(subs)
for i=1:155    
    if exist(['/mnt/tigrlab/scratch/nforde/homotopic/POND/edge_metrics/',subs(i).name,'_DWmat.csv']) == 2;
        DW = csvread(['/mnt/tigrlab/scratch/nforde/homotopic/POND/edge_metrics/',subs(i).name,'_DWmat.csv'],1, 0);
        TS = csvread(['/mnt/tigrlab/scratch/nforde/homotopic/POND/edge_metrics/',subs(i).name,'_TSmat.csv'],1, 0);
        Z = csvread(['/mnt/tigrlab/scratch/nforde/homotopic/POND/edge_metrics/',subs(i).name,'_Zmat.csv'],1, 0);
        
        % DW metrics
        %DWthr_abs = threshold_absolute(DW, thr);
        DWthr_prop = threshold_proportional(DW, 0.01); %p=1 all weights, p=0 no weights, 0.01
        DWb = weight_conversion(DW, 'binarize');
        DWthrb = weight_conversion(DWthr_prop, 'binarize');

        dwAss = assortativity_wei(DW, 0); %0 indicates undirected
        dwRC = rich_club_wu(DW);
        [dwScore, dwSn] = score_wu(DW, 600); %figure out value for s
        [dwKcore, dwKn, dwpeelorder, dwpeellevel] = kcore_bu(DWthrb, 3); %figure out value for k (3)
        
        % Strength
        %Zthr_abs = threshold_absolute(Z, thr);
        Zthr_prop = threshold_proportional(Z, 0.5); %p=1 all weights, p=0 no weights, 0.01
        Zb = weight_conversion(Z, 'binarize');
        Zthrb = weight_conversion(Zthr_prop, 'binarize');

        zAss = assortativity_wei(Z, 0); %0 indicates undirected
        zRC = rich_club_wu(Z);
        [zScore, zSn] = score_wu(Z, 1); %figure out value for s
        [zKcore, zKn, zpeelorder, zpeellevel] = kcore_bu(Zthrb, 100); %figure out value for k (3)
        
         % Stability
        %TSthr_abs = threshold_absolute(TS, thr);
        TSthr_prop = threshold_proportional(TS, 0.5); %p=1 all weights, p=0 no weights, 0.01
        TSb = weight_conversion(TS, 'binarize');
        TSthrb = weight_conversion(TSthr_prop, 'binarize');

        tsAss = assortativity_wei(TS, 0); %0 indicates undirected
        tsRC = rich_club_wu(TS);
        [tsScore, tsSn] = score_wu(TS, 125); %figure out value for s
        [tsKcore, tsKn, tspeelorder, tspeellevel] = kcore_bu(TSthrb, 10); %figure out value for k (3)
        
        
        metrics= [dwAss; dwSn; dwKn; zAss; zSn; zKn; tsAss; tsSn; tsKn];
        out(i,:)=metrics; %writes to new row for each sub
    else
        out(i,:)= [nan; nan; nan; nan; nan; nan; nan; nan; nan];
    end
        
end
%csvwrite('outfile',out) 


%%



