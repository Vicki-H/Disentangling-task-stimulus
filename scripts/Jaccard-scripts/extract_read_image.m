function [ image, header ] = extract_read_image( image_name )
%EXTRACT_READ_IMAGE A function that uses the spm functions to read in a
%header and an image but wraps both functions up into one

%   [ image, header ] = extract_read_image( image_name )

header = spm_vol(image_name);
image = spm_read_vols(header);

end