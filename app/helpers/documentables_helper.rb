module DocumentablesHelper

  def documentable_class(documentable)
    documentable.class.name.parameterize('_')
  end

  def max_documents_allowed(documentable)
    documentable.class.max_documents_allowed
  end

  def max_file_size(documentable_class)
    bytes_to_mega(documentable_class.max_file_size)
  end

  def accepted_content_types(documentable_class)
    documentable_class.accepted_content_types
  end

  def accepted_content_types_extensions(documentable_class)
=begin    
    documentable_class.accepted_content_types
                      .collect{ |content_type| ".#{content_type.split('/').last}" }
                      .join(",")
=end
  documentable_class.extension_content_types
                      .collect{ |content_type| ".#{content_type}" }
                      .join(",")

  end

  def documentable_humanized_accepted_content_types(documentable_class)
=begin
    documentable_class.accepted_content_types
                      .collect{ |content_type| content_type.split("/").last }
                      .join(", ")
=end
    documentable_class.extension_content_types
                      .collect{ |content_type| ".#{content_type}" }
                      .join(",")

  end

  def documentables_note(documentable,max_d=nil)
    if ( max_d.nil? )
      max_d=max_documents_allowed(documentable)
    end
    t "documents.form.note", max_documents_allowed: max_d,
                             accepted_content_types: documentable_humanized_accepted_content_types(documentable.class),
                             max_file_size: max_file_size(documentable.class)
  end

  def max_documents_allowed?(documentable)
    documentable.documents.count >= documentable.class.max_documents_allowed
  end
end
