module Trough
  module Pig
    module Hooks
      def update_document_usages

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

        if archived_at_changed?
          if archived_at.present?
            DocumentUsage.where(pig_content_package_id: id).each(&:deactivate!)
          else
            DocumentUsage.where(pig_content_package_id: id).each(&:activate!)
          end
        end
      end

      def determine_document_change(key, content_chunk)
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
        documents_in_old_text = json_content_was.empty? ? [] : find_documents((json_content_was['content_chunks'][key] || {})['value'])
        documents_in_new_text = find_documents(json_content['content_chunks'][key]['value'])

        new_documents = documents_in_new_text - documents_in_old_text
        removed_documents = documents_in_old_text - documents_in_new_text

        new_documents.each do |doc|
          document = Document.find_by(slug: doc)
          next if document.nil?
          document.create_usage!(self.id)
        end

        removed_documents.each do |doc|
          document = Document.find_by(slug: doc)
          next if document.nil?
          document_usage = DocumentUsage.find_or_initialize_by(trough_document_id: document.id, pig_content_package_id: self.id)
          document_usage.deactivate! if document_usage
        end
      end

      def find_documents(value)
        # Find all links to /documents/:slug and return the slugs
        return [] if value.nil?
        value.scan(/href=\S*\/documents\/(\S+[^\\])\\?['"]/).flatten
      end

      def unlink_document_usages
        DocumentUsage.where(pig_content_package_id: id).each(&:unlink_content_package!)
      end
    end
  end
end
