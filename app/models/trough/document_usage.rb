module Trough
  class DocumentUsage < ActiveRecord::Base

    belongs_to :document, foreign_key: 'trough_document_id'
    validates :document, presence: true

    if GemHelper.gem_loaded? :pig
      belongs_to :content_package, class_name: '::Pig::ContentPackage', foreign_key: 'pig_content_package_id'
      belongs_to :unscoped_content_package, -> { unscope(where: :archived_at) }, class_name: '::Pig::ContentPackage', foreign_key: 'pig_content_package_id'
      validates :content_package, presence: { allow_nil: true }
      validates :document, uniqueness: { scope: :content_package, allow_nil: true }
    end

    def self.active
      where(active: true)
    end

    def activate!
      update_attribute(:active, true)
    end

    def deactivate!
      update_attribute(:active, false)
    end

    def unlink_content_package!
      update_attributes(active: false, pig_content_package_id: nil)
    end
  end
end
