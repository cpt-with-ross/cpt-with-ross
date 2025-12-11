module ApplicationHelper
  # Generates the export path for a given resource using ExportConfig
  def export_path_for(item)
    build_exportable_path(item, :export)
  end

  # Generates the share path for a given resource using ExportConfig
  def share_path_for(item)
    build_exportable_path(item, :share)
  end

  private

  # Dynamically builds export/share paths based on ExportConfig registration
  # Baseline requires special handling due to nested route structure
  def build_exportable_path(item, action)
    key = ExportConfig.key_for_model(item)

    if key == :baseline
      send("#{action}_index_event_baseline_path", item.index_event)
    else
      send("#{action}_#{key}_path", item)
    end
  end

  public

  # Generates the standard Print/Export/Share dropdown items for a resource.
  # Accepts either explicit paths or a resource object.
  #
  # @param item [Object] Exportable resource (AbcWorksheet, AlternativeThought, etc.)
  # @return [Array<Hash>] Array of menu item hashes for action_dropdown partial
  def document_actions(item: nil, export_path: nil, share_path: nil)
    export_path ||= export_path_for(item)
    share_path ||= share_path_for(item)

    [
      {
        label: 'Print',
        icon: 'fa-solid fa-print',
        path: "#{export_path}?print=true",
        target: '_blank',
        turbo: false,
        controller: 'document-actions',
        action: 'click->document-actions#printFromDropdown'
      },
      {
        label: 'Export',
        icon: 'fa-solid fa-file-pdf',
        path: export_path,
        target: '_blank',
        turbo: false
      },
      {
        label: 'Share',
        icon: 'fa-solid fa-envelope',
        path: share_path,
        turbo: false,
        controller: 'document-actions',
        action: 'click->document-actions#shareFromDropdown'
      }
    ]
  end
end
