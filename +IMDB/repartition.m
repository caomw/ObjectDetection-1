function imdb = repartition( imdb, partitions )
%REPARTITION Regardless of the current distribution of images+labels within
%different sets (training, validation and testing), create a new
%partitioning. Distribution among labels is kept within classes (i.e. if 
% they are balanced, they will also be balanced within each set).
%
% INPUT:
%
%   imdb = the imdb struct that you want to repartition
%   partitions = a 3 element vector where each entry specifies the
%   percentage of the partition with respect to the total datasize, e.g. [0.6 0.2 0.2]
%
% @Author: Christoph Baur

    % Gain access to all methods of the package
    import IMDB.*
    
    % Find label distribution among classes
    label_distributions = [];
    for c=1:length(imdb.meta.classes)
        label_distributions(1, c) = sum(imdb.images.labels == imdb.meta.classes(c));
    end

    % Algorithm 1: collect partitions(s) * label_counts(c) randomly
    % and set their set to be s
    % Iterate over all sets
%     label_counts = zeros(1, length(label_distributions));
%     for s=1:3
%        % Iterate over all classes
%        for c=1:length(imdb.meta.classes)
%            % Add to set while retaining the label distributions among
%            % classes
%        end
%     end
    
   for c=1:length(imdb.meta.classes)
       % Add to set while retaining the label distributions among
       % classes

       % Algorithm 2: for s=1 select the first partitions(s) *
       % label_counts(c) images from all the images with label c
       idx = find(imdb.images.labels == c);
       
       % Images that will be set to set 1 (Training)
       idx1 = idx(1:floor(partitions(1)*length(idx)));
       imdb.images.set( idx1 ) = 1;
       
       % Images that will be set to set 2 (Validation)
       idx2 = idx(floor(partitions(1)*length(idx))+1:floor((partitions(1)+partitions(2))*length(idx)));
       imdb.images.set( idx2 ) = 2;
       
       % Images that will be set to set 3 (Testing)
       idx3 = idx(floor((partitions(1)+partitions(2))*length(idx))+1:end);
       imdb.images.set( idx3 ) = 3;
   end
   
   % Correct the mean
   imdb.images.dataMean = mean(imdb.images.data(:,:,:,find(imdb.images.set == 1)), 4);
end

