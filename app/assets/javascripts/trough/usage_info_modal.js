var DocumentInfoModal = (function () {
  "use strict";

  $(document).ready(function(){
    $('body').on('click', '[data-document-info-modal]', function (event) {
      event.preventDefault();
      var openingLink = $(event.currentTarget);
      show(openingLink.data('document-info-modal'));
    });
  });

  function show(slug) {
    $.get('/documents/' + slug + '/info', function(data) {
      var compiled = _.template(
        "<div class='row'>" +
          "<div class='col-md-6'>" +
            "<label class='col-primary'>Filename</label>" +
            "<p><i><%= data.file_filename %></i></p>" +
          "</div>" +
          "<div class='col-md-6'>" +
            "<label class='col-primary'>Filesize</label>" +
            "<p><i><%= data.file_size %></i></p>" +
          "</div>" +
        "</div>" +
        "<div class='row'>" +
          "<div class='col-md-6'>" +
            "<label class='col-primary'>Author</label>" +
            "<p><i><%= data.uploader %></i></p>" +
          "</div>" +
          "<div class='col-md-6'>" +
            "<label class='col-primary'>Uploaded</label>" +
            "<p><i><%= data.uploaded_on %></i></p>" +
          "</div>" +
        "</div>" +
        "<label class='col-primary'>description</label>" +
        "<div class='document-description'> <%= data.description %> </div>" +
        "<table id='usage_link_list' class='cms-table'>" +
        "<thead>" +
          "<tr>" +
            "<th>Pages</th>" +
            "<th>Active</th>" +
            "<th>Download count</th>" +
          "</tr>" +
        "</thead>" +
        "<% _.each(data.document_usages, function(usage) {  %>" +
          "<tr>" +
          "<td><%= usage.content_package.name %></td>" +
          "<td><%= usage.active %></td>" +
          "<td><%= usage.download_count %></td>" +
          "</tr>" +
        "<% }); %>" +
        "</table>" +
        "<a class='btn btn-primary pull-right' href=\"/documents/<%= data.slug %>\" ><i class='fa fa-download'></i> Download</a>" +
        "<a class='btn btn-error pull-right' href=''><i class='fa fa-trash-o'></i> Delete</a>" +
        "<div class='clearfix'></div>",
        {variable: 'data'});
      $('#usageLinks .modal-body').html(compiled(data));
    });

    $('#usageLinks').modal("show");
  }

  return {
    show: show
  };

})();

// %td.documents-delete-column
//   =link_to('Delete', document_path(document), method: :delete, remote: true, class: 'fa fa-trash-o document-delete', data: {confirm: 'Are you sure? This cannot be undone'} )