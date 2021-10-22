class Admin::Legislation::ProcessTypologiesController < Admin::Legislation::ProcessesController
  before_action :load_data, only: [:show, :new, :update, :edit, :create]

  def index
    @typologies = ::Legislation::ProcessTypology.order('id ASC').page(params[:page])
  end

  def show
    render :edit
  end

  def new
    @typology = ::Legislation::ProcessTypology.new
  end

  def create
    #campo active a true per default - lato view è stato reso hidden
    @typology = ::Legislation::ProcessTypology.new(legislation_process_typology_params)

    if @typology.save
      flash[:notice] = t('admin.legislation.process_typologies.form.create_successful')
      redirect_to admin_legislation_process_typologies_path
    else
      flash.now[:alert] = t('admin.legislation.process_typologies.form.save_failed')
      render :new
    end
  end

  def edit
  end

  def update
    if @typology.update(legislation_process_typology_params)
      flash[:notice] = t('admin.legislation.process_typologies.form.update_successful')
      redirect_to admin_legislation_process_typologies_path
    else
      flash.now[:alert] = t('admin.legislation.process_typologies.form.save_failed')
      render :edit
    end
  end

  def destroy_map_location_association
    # Override obbligatorio
  end

  def load_data
    @typology = ::Legislation::ProcessTypology.where(id: params[:id]).first
    @typologies = ::Legislation::ProcessTypology.all
  end

  private

  def legislation_process_typology_params
    params.require(:legislation_process_typology).permit(
        :name,
        :active
    )
  end
end
