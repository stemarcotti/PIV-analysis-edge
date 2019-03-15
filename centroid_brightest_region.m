for kk = 1:nt
        
        currentFrame = double(imread([directory '/' file],kk))/255;
        cellOutline = detectObjectBw(currentFrame, dilationSize, erosionSize, connectivityFill);
        
        im = currentFrame .* cellOutline;
        im(cellOutline == 0) = NaN;
        
        % intensity(kk,1) = nanmean(im(:));

        mask = im > quantile(im(:), 0.75);
        
        [L,~] = bwlabel(mask);
        stats = regionprops(L, 'Area', 'Centroid');
        allArea = [stats.Area];
        area_largest_obj = max(allArea(:));
        mask_largest_obj = bwareaopen(mask,area_largest_obj);
        
        stats_largest_obj = regionprops(mask_largest_obj, 'Centroid');
        centr(kk,:) = stats_largest_obj.Centroid;

end