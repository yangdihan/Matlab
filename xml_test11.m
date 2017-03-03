function xml_test11
%AUTHOR: Dihan Yang, Yumo Chi
t = cputime;
inputImagePathName = 'E:\Yang\LabelMe_Photos\collection\Images\users\djrbrts2\cranes\';
outputImagePathName = 'E:\Yang\testFolder\Output\';
inputXMLPathName = 'E:\Yang\LabelMe_Photos\collection\Annotations\users\djrbrts2\cranes\';
outputXMLPathName = 'E:\Yang\testFolder\Output\';
imageList = dir(fullfile(inputImagePathName, '*.jpg'));
XMLList = dir(fullfile(inputXMLPathName, '*.xml'));

for l = 1:numel(XMLList)
    xmlfile = fullfile(inputXMLPathName, XMLList(l).name);
    docNewNode = xmlread(xmlfile);
    
    import javax.xml.xpath.*
    factory = XPathFactory.newInstance;
    xpath = factory.newXPath;
    
    expression = xpath.compile('annotation/filename');
    filenameNode = expression.evaluate(docNewNode, XPathConstants.NODE);
    filename = char(filenameNode.getTextContent);
    
    expression = xpath.compile('annotation/folder');
    folderNode = expression.evaluate(docNewNode, XPathConstants.NODE);
    folder = char(folderNode.getTextContent);
    
    expression = xpath.compile('annotation/source/submittedBy');
    submittedByNode = expression.evaluate(docNewNode, XPathConstants.NODE);
    submittedBy = char(submittedByNode.getTextContent);
    
    expression = xpath.compile('annotation/imagesize/nrows');
    nrowsNode = expression.evaluate(docNewNode, XPathConstants.NODE);
    nrows = str2num(nrowsNode.getTextContent);
    
    expression = xpath.compile('annotation/imagesize/ncols');
    ncolsNode = expression.evaluate(docNewNode, XPathConstants.NODE);
    ncols = str2num(ncolsNode.getTextContent);
    
    %CALCULATING SHRINKAGE RATIO
    if (nrows >= ncols)
        ratio = 600 / ncols;
    else
        ratio = 600 / nrows;
    end
    
    %MODIFYING IMAGE SIZE
    nrowsNew = round(ratio * nrows);
    ncolsNew = round(ratio * ncols);
    
    %CONTINUE READING ORIGINAL XML
    annotationNode = docNewNode.getDocumentElement;
    entries = annotationNode.getChildNodes;
    
    i = 4;
    j=i-3;
    
    objectNode = entries.item(i);
    objectInfo = objectNode.getChildNodes;
    
    while ~isempty(objectNode)
        name = char(objectInfo.getElementsByTagName('name').item(0).getTextContent);
        deleted = char(objectInfo.getElementsByTagName('deleted').item(0).getTextContent);
        verified = char(objectInfo.getElementsByTagName('verified').item(0).getTextContent);
        occluded = char(objectInfo.getElementsByTagName('occluded').item(0).getTextContent);
        attributes = char(objectInfo.getElementsByTagName('attributes').item(0).getTextContent);
        date = char(objectInfo.getElementsByTagName('date').item(0).getTextContent);
        id = char(objectInfo.getElementsByTagName('id').item(0).getTextContent);
        type = char(objectInfo.getElementsByTagName('type').item(0).getTextContent);
        username = char(objectInfo.getElementsByTagName('username').item(0).getTextContent);
        x1 = round(str2num(objectInfo.getElementsByTagName('x').item(0).getTextContent) * ratio);
        y1 = round(str2num(objectInfo.getElementsByTagName('y').item(0).getTextContent) * ratio);
        x2 = round(str2num(objectInfo.getElementsByTagName('x').item(1).getTextContent) * ratio);
        y2 = round(str2num(objectInfo.getElementsByTagName('y').item(1).getTextContent) * ratio);
        x3 = round(str2num(objectInfo.getElementsByTagName('x').item(2).getTextContent) * ratio);
        y3 = round(str2num(objectInfo.getElementsByTagName('y').item(2).getTextContent) * ratio);
        x4 = round(str2num(objectInfo.getElementsByTagName('x').item(3).getTextContent) * ratio);
        y4 = round(str2num(objectInfo.getElementsByTagName('y').item(3).getTextContent) * ratio);
        
        deletedCheck = strcmp(deleted,'0');
        if deletedCheck == 1
            infoMatrix(j,:) = {name,deleted,verified,occluded,attributes,date,id,type,username};
            coordinateMatrix(j,:) = [x1,y1,x2,y2,x3,y3,x4,y4];
            i = i+1;
            j = i-3;
        end
        if deletedCheck == 0
            i = i+1;
            j = i-4;
        end
        
        objectNode = entries.item(i);
        if (isempty(objectNode))
            break
        end
        objectInfo = objectNode.getChildNodes;
    end
    
    matrixSize = size(coordinateMatrix);
    matrixRowNumber = matrixSize(1);
    
    %GENERATING MODIFIED XML
    docNode = com.mathworks.xml.XMLUtils.createDocument('annotation_modified');
    
    filenameNode = docNode.createElement('filename');
    filenameNode.appendChild(docNode.createTextNode(sprintf('%s',filename)));
    docNode.getDocumentElement.appendChild(filenameNode);
    
    filenameNode = docNode.createElement('folder');
    filenameNode.appendChild(docNode.createTextNode(sprintf('%s',folder)));
    docNode.getDocumentElement.appendChild(filenameNode);
    
    sourceNode = docNode.createElement('source');
    docNode.getDocumentElement.appendChild(sourceNode);
    submittedByNode = docNode.createElement('submittedBy');
    submittedByNodeText = docNode.createTextNode(sprintf('%s',submittedBy));
    submittedByNode.appendChild(submittedByNodeText);
    sourceNode.appendChild(submittedByNode);
    
    imagesizeNode = docNode.createElement('imagesize');
    docNode.getDocumentElement.appendChild(imagesizeNode);
    nrowsNewNode = docNode.createElement('nrowsNew');
    nrowsNewNodeText = docNode.createTextNode(sprintf('%i',nrowsNew));
    nrowsNewNode.appendChild(nrowsNewNodeText);
    imagesizeNode.appendChild(nrowsNewNode);
    
    ncolsNewNode = docNode.createElement('ncolsNew');
    ncolsNewNodeText = docNode.createTextNode(sprintf('%i',ncolsNew));
    ncolsNewNode.appendChild(ncolsNewNodeText);
    imagesizeNode.appendChild(ncolsNewNode);
    
    for k = 1:matrixRowNumber
        objectNode = docNode.createElement('object');
        docNode.getDocumentElement.appendChild(objectNode);
        nameNode = docNode.createElement('name');
        nameNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,1))));
        nameNode.appendChild(nameNodeText);
        objectNode.appendChild(nameNode);
        
        deletedNode = docNode.createElement('deleted');
        deletedNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,2))));
        deletedNode.appendChild(deletedNodeText);
        objectNode.appendChild(deletedNode);
        
        verifiedNode = docNode.createElement('verified');
        verifiedNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,3))));
        verifiedNode.appendChild(verifiedNodeText);
        objectNode.appendChild(verifiedNode);
        
        occludedNode = docNode.createElement('occluded');
        occludedNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,4))));
        occludedNode.appendChild(occludedNodeText);
        objectNode.appendChild(occludedNode);
        
        attributesNode = docNode.createElement('attributes');
        attributesNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,5))));
        attributesNode.appendChild(attributesNodeText);
        objectNode.appendChild(attributesNode);
        
        dateNode = docNode.createElement('date');
        dateNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,6))));
        dateNode.appendChild(dateNodeText);
        objectNode.appendChild(dateNode);
        
        idNode = docNode.createElement('id');
        idNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,7))));
        idNode.appendChild(idNodeText);
        objectNode.appendChild(idNode);
        
        typeNode = docNode.createElement('type');
        typeNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,8))));
        typeNode.appendChild(typeNodeText);
        objectNode.appendChild(typeNode);
        
        polygonNode = docNode.createElement('polygon');
        docNode.getDocumentElement.appendChild(polygonNode);
        objectNode.appendChild(polygonNode);
        usernameNode = docNode.createElement('username');
        usernameNodeText = docNode.createTextNode(sprintf('%s',char(infoMatrix(k,9))));
        usernameNode.appendChild(usernameNodeText);
        polygonNode.appendChild(usernameNode);
        
        ptNode = docNode.createElement('pt');
        docNode.getDocumentElement.appendChild(ptNode);
        polygonNode.appendChild(ptNode);
        xNode = docNode.createElement('x');
        xNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,1)));
        xNode.appendChild(xNodeText);
        ptNode.appendChild(xNode);
        yNode = docNode.createElement('y');
        yNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,2)));
        yNode.appendChild(yNodeText);
        ptNode.appendChild(yNode);
        
        ptNode = docNode.createElement('pt');
        docNode.getDocumentElement.appendChild(ptNode);
        polygonNode.appendChild(ptNode);
        xNode = docNode.createElement('x');
        xNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,3)));
        xNode.appendChild(xNodeText);
        ptNode.appendChild(xNode);
        yNode = docNode.createElement('y');
        yNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,4)));
        yNode.appendChild(yNodeText);
        ptNode.appendChild(yNode);
        
        ptNode = docNode.createElement('pt');
        docNode.getDocumentElement.appendChild(ptNode);
        polygonNode.appendChild(ptNode);
        xNode = docNode.createElement('x');
        xNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,5)));
        xNode.appendChild(xNodeText);
        ptNode.appendChild(xNode);
        yNode = docNode.createElement('y');
        yNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,6)));
        yNode.appendChild(yNodeText);
        ptNode.appendChild(yNode);
        
        ptNode = docNode.createElement('pt');
        docNode.getDocumentElement.appendChild(ptNode);
        polygonNode.appendChild(ptNode);
        xNode = docNode.createElement('x');
        xNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,7)));
        xNode.appendChild(xNodeText);
        ptNode.appendChild(xNode);
        yNode = docNode.createElement('y');
        yNodeText = docNode.createTextNode(sprintf('%i',coordinateMatrix(k,8)));
        yNode.appendChild(yNodeText);
        ptNode.appendChild(yNode);
    end
    
    modifiedFileName = strcat(outputXMLPathName,XMLList(l).name);
    xmlwrite(modifiedFileName, docNode);
    
    inputImage = imread(fullfile(inputImagePathName, imageList(l).name));
    outputImage = imresize(inputImage,[nrowsNew,ncolsNew]);
    modifiedImageName = strcat(outputImagePathName,imageList(l).name);
    imwrite(outputImage,modifiedImageName);
    
end
disp('number of images is: ');
disp(numel(XMLList));
e = cputime-t;
disp('time taking is: ');
disp(e);
averageTime = e/numel(XMLList);
disp('average time taking is: ');
disp(averageTime);

end
# this is a branch
