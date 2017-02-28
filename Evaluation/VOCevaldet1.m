 function [ap,npos,nd,total_tp,total_fp ] = VOCevaldet1(opts,imdb,cls,draw)

% load test set
fprintf('%s: pr: evaluating detections\n',cls);

val = find(imdb.set == 2) ;
pre=['Eval' filesep cls] ;
mkdir(fullfile(opts.resultDir,pre));
gtids={};  


gt_from_seg=true ;
%pref='gt_from_seg';
%mkdir(fullfile(opts.resultDir,pref));

npos=0;
gt(numel(val))=struct('BB',[],'diff',[],'det',[]);
for i=1:numel(val)     
        j= val(i);
       % name=strcat('img_',sprintf('%07d',i));
       name=sprintf('img_%d',i);
       gtids{i} =name;      
          if(gt_from_seg)
               % extract objects of class
               obj=imdb.objects{1,j};
               
              no_of_gt_detections=0;
              total_detections= size(obj.bbox,2);
               xmins=[];
               ymins=[];
               xmaxs=[];
               ymaxs=[];
                for k=1:total_detections
                     clsind=obj.class(k) ;
                     cls_c = opts.classes{clsind};
                 
                    if(strcmp(cls_c,cls))
                        bb=obj.bbox(k);
                        xmins=[xmins;bb.xmin];
                        ymins=[ymins;bb.ymin];
                        xmaxs=[xmaxs;bb.xmax];
                        ymaxs=[ymaxs;bb.ymax];
                        no_of_gt_detections=no_of_gt_detections+1;
                    end 
                end 
               
                gt(i).BB= [xmins,ymins,xmaxs,ymaxs]'; 
                gt(i).diff=false(no_of_gt_detections,1);
                gt(i).det=false(no_of_gt_detections,1);
             
               
               %for j=1:no_of_gt_detections
               %   bbgt=cat(1,imdb.objects(1,i).bbox(j))';
               %   rectangle('Position',[bbgt(1) bbgt(2) (bbgt(3)-bbgt(1)+1) (bbgt(4)-bbgt(2)+1)],'EdgeColor','b','LineWidth',1);
              % end 
             
            
                
               
                
                
               
          
          else 
               % To set difficult detections
               
                recs=PASreadrecord(fullfile(opts.annopath,sprintf('%s.xml', name)));
                clsinds=strmatch(cls,{recs.objects(:).class},'exact');
         
                hr=256/recs.size.height;
                wr= 256/recs.size.width;
                gt(i).BB=(cat(1,recs.objects(clsinds).bbox) .* repmat([wr,hr,wr,hr],length(clsinds),1))';
                gt(i).diff=[recs.objects(clsinds).difficult];
                gt(i).det=false(length(clsinds),1);
                
             
               
          end 
        
         
       
        
         npos=npos+sum(~gt(i).diff);
end
 

fprintf('total ground truth positive detections %d',npos);
 % hash image ids
%hash=VOChash_init(gtids);
        

% load results
result_file=sprintf('%s_det_val_%s.txt','comp3',cls);
filename=fullfile(opts.resultDir,result_file);

[ids,b1,b2,b3,b4,confidence1,perct1,confidence2,perct2, contbytotal]=textread(filename,'%s %f %f %f %f %f %f %f %f %f');
BB=[b1 b2 b3 b4]';
confidence=perct2 .* contbytotal;
perct=perct2;

high_perct_ind=find(perct > 0.3);
ids=ids(high_perct_ind);
%Rename to make it 11 length long
%for m=1:length(ids)
%    namme=ids{m};
%    itn_v=namme(5:end);
%    namme=strcat('img_',sprintf('%07d',str2double(itn_v)));
%    ids{m}=namme;
%end 


BB=BB(:,high_perct_ind);
perct=perct(high_perct_ind);
confidence=confidence(high_perct_ind);

% sort detections by decreasing confidence
[sc,si]=sort(-confidence);
ids=ids(si);
BB=BB(:,si);
perct=perct(si);
confidence=confidence(si);
% assign detections to ground truth objects
nd=length(confidence);
tp=zeros(nd,1);
fp=zeros(nd,1);
tic;

gtipbyg=[];
gtipbyp=[];
gtifpbyg1=[];
gtifpbyg2=[];
gtifpbyg=[];
fprintf('Total Detections %d\n',nd);
for d=1:nd
    % display progress
  %  if toc>1
  %      fprintf('%s: pr: compute: %d/%d\n',cls,d,nd);
  %      drawnow;
        tic;
  %  end
    
    % find ground truth image
  %  i=VOChash_lookup(hash,ids{d});
    namme=ids{d};
    i= str2double(namme(5:end));
    if isempty(i)
        error('unrecognized image "%s"',ids{d});
    elseif length(i)>1
        error('multiple image "%s"',ids{d});
    end
     ind=val(i);
   %  ind=strmatch(sprintf('%s.png',ids{d}),cellstr(imdb.images.filenames) , 'exact');
     img=imdb.images{ind};
           
    f=figure;  imshow(img); 
    hold on ;
    % assign detection to ground truth object if any
    bb=BB(:,d);
    ovmax=-inf;
    jmax=0;
    intrsctn_area=0;
    g_area=1; %setting it to 1 becaz it is divided
    
    for j=1:size(gt(i).BB,2)
        
       bbgt=gt(i).BB(:,j);
       gw= bbgt(3)-bbgt(1)+1;
       gh= bbgt(4)-bbgt(2)+1;
       if gt(i).diff(j)
         hold on ; rectangle('Position',[bbgt(1),bbgt(2),gw,gh], 'EdgeColor','k','LineStyle' ,':','LineWidth',2);     
       else 
         hold on ; rectangle('Position',[bbgt(1),bbgt(2),gw,gh], 'EdgeColor','k','LineWidth',2);
      
       end 
           
        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
        iw=bi(3)-bi(1)+1;
        ih=bi(4)-bi(2)+1;
        
        
        if iw>0 & ih>0                
            % compute overlap as area of intersection / area of union
            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
               (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
               iw*ih;
            ov=iw*ih/ua;
                           
            if ov>ovmax
                ovmax=ov;
                jmax=j;
                intrsctn_area= iw*ih;
            end
        end
        
    end
    
      if(jmax ~=0)            
          %this detection was assigned to this ground truth %colored with
          %blue
           bbgt_ass=gt(i).BB(:,jmax);  
           gw_ass= bbgt_ass(3)-bbgt_ass(1)+1;
           gh_ass= bbgt_ass(4)-bbgt_ass(2)+1;
           
           g_area= gw_ass * gh_ass;
           
           hold on ; rectangle('Position',[bbgt_ass(1),bbgt_ass(2),gw_ass,gh_ass], 'EdgeColor','b','LineWidth',2);

          
      end 

        pw= bb(3)-bb(1)+1;
        ph= bb(4)-bb(2)+1;
        p_area= pw*ph;
       
            
        
           
    % assign detection as true positive/don't care/false positive
    if ovmax>=opts.minoverlap
        if ~gt(i).diff(jmax)
            if ~gt(i).det(jmax)
                tp(d)=1;            % true positive
		        gt(i).det(jmax)=true;
                hold on ; rectangle('Position',[bb(1),bb(2),pw,ph], 'EdgeColor','g','LineWidth',2);
                titl=sprintf('TP:Correct Detection, IOU:%f CONF:%f PER:%f',ovmax,confidence(d),perct(d));
                name= sprintf('%s_%d_tp',ids{d},d);
            else
                fp(d)=1;            % false positive (multiple detection)
                hold on ; rectangle('Position',[bb(1),bb(2),pw,ph], 'EdgeColor','r','LineStyle',':','LineWidth',2);
                titl=sprintf('FP:Multiple Detection, IOU:%f CONF:%f PER:%f',ovmax,confidence(d),perct(d));
                name= sprintf('%s_%d_fpm',ids{d},d);
            end
            gtipbyg =[gtipbyg;intrsctn_area/g_area];
            gtipbyp = [gtipbyp; intrsctn_area/p_area];
            gtifpbyg1=[gtifpbyg1;intrsctn_area/g_area ];
            gtifpbyg=[gtifpbyg;intrsctn_area/g_area];
        else 
            %difficult detection
             hold on ; rectangle('Position',[bb(1),bb(2),pw,ph], 'EdgeColor','y','LineWidth',2);
             titl=sprintf('NA:Difficult Detection, IOU:%f CONF:%f PER:%f',ovmax,confidence(d),perct(d));
             name= sprintf('%s_%d_dif',ids{d},d);
            
        end
    else
        fp(d)=1;                    % false positive
        gtipbyg =[gtipbyg;intrsctn_area/g_area];
        gtipbyp = [gtipbyp; intrsctn_area/p_area];
        gtifpbyg2=[gtifpbyg2;intrsctn_area/g_area ];
        gtifpbyg=[gtifpbyg;intrsctn_area/g_area];
        
        hold on ; rectangle('Position',[bb(1),bb(2),pw,ph], 'EdgeColor','r','LineWidth',2);
        titl=sprintf('FP: False Detection, IOU:%f CONF:%f PER:%f',ovmax,confidence(d),perct(d));
        name= sprintf('%s_%d_fp',ids{d},d);
       
          
    end
    
    title(titl);
    savefig(f,fullfile(opts.resultDir,pre,sprintf('%s.fig',name)));
    saveas(f,fullfile(opts.resultDir,pre, sprintf('%s.png',name)));
    close(f);
            
end

% compute precision/recall
total_fp=sum(fp);
total_tp=sum(tp);
fprintf('True Detections %d\n',total_tp);
fprintf('False Detections %d\n',total_fp);


fp=cumsum(fp);
tp=cumsum(tp);
rec=tp/npos;
prec=tp./(fp+tp);

ap=VOCap(rec,prec);
fprintf('Average Precision %f\n',ap);
if draw
    f1=figure;
    scatter(gtipbyp,gtipbyg);
    grid;
    xlabel 'GT int P / P'
    ylabel 'GT int P / G'
    savefig(f1,fullfile(opts.resultDir,pre, 'Detections.fig'));
    
    % plot precision/recall
    f2=figure;
    plot(rec,prec,'-');
    grid;
    xlabel 'recall'
    ylabel 'precision'
    title(sprintf('class: %s, subset: %s, AP = %.3f',cls,'val',ap));
    savefig(f2,fullfile(opts.resultDir,pre, 'EVAL_d.fig'));
   
   f3=figure;
   histogram( gtifpbyg1);
   title('FP: Multiple Detections');
   xlabel 'GT intersection FP / GT';
   ylabel 'count';
   savefig(f3,fullfile(opts.resultDir,pre, 'FalseDetections_MD.fig'));
   
   f4=figure;
   histogram( gtifpbyg2);
   title('FP: Less IOU ');
   xlabel 'GT intersection FP / GT';
   ylabel 'count';
   savefig(f4,fullfile(opts.resultDir,pre, 'FalseDetections_LESS_IOU.fig'));
   
   f5=figure;
   histogram( gtifpbyg);
   title('GT intersection FP / GT');
   xlabel 'GT intersection FP / GT';
   ylabel 'count';
   savefig(f5,fullfile(opts.resultDir,pre, 'FalseDetections.fig'));
   
   close(f1);
   close(f2);
   close(f3);
   close(f4);
   close(f5);
end
 