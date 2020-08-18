module Trough
  module Pig
    module Hooks
      def update_document_usages

        json_content_was = get_previous_value("json_content")

        if json_content_was.empty?
          changed_chunks = (json_content['content_chunks'] || {}).select do |k, v|
            v && v['field_type'].in?(%w(document rich_content text))
          end
        else
          changed_chunks = (json_content['content_chunks'] || {}).select do |k, v|
            new_value = v['value']
            was_value = (json_content_was['content_chunks'][k] || {})['value']
            v['field_type'].in?(%w(document rich_content text)) &&
              was_value != new_value
          end
        end

        changed_chunks.each do |key, changed_chunk|
          send("determine_#{changed_chunk['field_type']}_change", key, changed_chunk)
        end

        if get_previous_value("archived_at") != archived_at
          if archived_at.present?
            DocumentUsage.where(pig_content_package_id: id).each(&:deactivate!)
          else
            DocumentUsage.where(pig_content_package_id: id).each(&:activate!)
          end
        end
      end

      def determine_document_change(key, content_chunk)
        json_content_was = get_previous_value("json_content")
        if json_content_was['content_chunks'] &&
            json_content_was['content_chunks'][key] &&
            json_content['content_chunks'] &&
            json_content['content_chunks'][key] &&
            json_content_was['content_chunks'][key] != json_content['content_chunks'][key]
          old_document_id = json_content_was['content_chunks'][key]['value']
          document_usage = DocumentUsage.find_or_initialize_by(
            trough_document_id: old_document_id,
            pig_content_package_id: id
          )
          document_usage.deactivate!
        end
        if content_chunk['value'].present?
          document = Document.find(content_chunk['value'])
          document.create_usage!(id) if document
        end
      end

      def determine_rich_content_change(key, content_chunk)
        determine_text_change(key, content_chunk)
      end

      def determine_text_change(key, content_chunk)
        json_content_was = get_previous_value("json_content")
        documents_in_old_text = json_content_was.empty? ? [] : find_documents((json_content_was['content_chunks'][key] || {})['value'])
        documents_in_new_text = find_documents(json_content['content_chunks'][key]['value'])

        new_documents = documents_in_new_text - documents_in_old_text
        removed_documents = documents_in_old_text - documents_in_new_text

        new_documents.each do |doc|
          slug = File.basename(doc,File.extname(doc)) # Remove extension 
          document = Document.find_by(slug: slug)
          next if document.nil?
          document.create_usage!(self.id)
        end

        removed_documents.each do |doc|
          slug = File.basename(doc,File.extname(doc)) # Remove extension 
          document = Document.find_by(slug: slug)
          next if document.nil?
          document_usage = DocumentUsage.find_or_initialize_by(trough_document_id: document.id, pig_content_package_id: self.id)
          document_usage.deactivate! if document_usage
        end

      end

      def find_documents(value)
        # Find all links to /documents/:slug and return the slugs
        return [] if value.nil?
        html = Nokogiri::HTML(value)
        links = find_links_for_documents(html)
        grab_slugs_from_links(links)
      end

      def find_links_for_documents(html)
        html.xpath("//a[contains(@href, '/documents/')]")
      end

      def grab_slugs_from_links(links)
        links.map do |link|
          link[:href].split("/documents/").last
        end
      end

      def unlink_document_usages
        DocumentUsage.where(pig_content_package_id: id).each(&:unlink_content_package!)
      end

      def get_previous_value(field)
        if versions && versions.last
          ret = versions.last.reify.send(field)
        else
          ret = send(field)
        end
        return ret
      end
    end
  end
end
