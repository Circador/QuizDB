class TossupsController < ApplicationController
  before_action :set_tossup, only: [:show, :update, :destroy]

  QUESTION_SEARCH_LIMT = 15

  def filter_options
    render json: {
      search_type: ["Question", "Answer"],
      question_type: ["Tossup", "Bonus"],
      # pluck to speed up query a little, instead of accessing each record
      category: Category.order(:name).pluck(:name, :id).map { |c| {
        name: c[0],
        id: c[1]
        } },
      subcategory: Subcategory.order(:name).pluck(:name, :id).map { |c| {
        name: c[0],
        id: c[1]
        } },
      tournament: Tournament.all.order(year: :desc, name: :asc)
        .pluck(:name, :id, :difficulty, :quality, :year).map { |c| {
          name: c[0],
          id: c[1],
          difficulty: c[2].titleize,
          quality: c[3],
          year: c[4]
        } },
      difficulty: Tournament.difficulties.map { |k,v | {
        number: v,
        name: k,
        title: k.titleize
        } }
    }
  end

  def search
    query = search_params[:query]
    limit = search_params[:limit].blank? || search_params[:limit] != 'false'

    if search_params[:filters]
      if search_params[:filters][:question_type]
        question_type_filter = search_params[:filters][:question_type]
        if (["Tossup", "Bonus"] - question_type_filter).empty?
          tossups = Tossup.filter_by_defaults(search_params[:filters], query)
          bonuses = Bonus.filter_by_defaults(search_params[:filters], query)
        elsif question_type_filter.include?("Tossup")
          tossups = Tossup.filter_by_defaults(search_params[:filters], query)
          bonuses = Bonus.none
        else
          tossups = Tossup.none
          bonuses = Bonus.filter_by_defaults(search_params[:filters], query)
        end
      else
        tossups = Tossup.filter_by_defaults(search_params[:filters], query)
        bonuses = Bonus.filter_by_defaults(search_params[:filters], query)
      end
    else
      tossups = Tossup.filter_by_defaults({}, query)
      bonuses = Bonus.filter_by_defaults({}, query)
    end

    tossups = tossups.includes(:tournament, :category, :subcategory)
    bonuses = bonuses.includes(:tournament, :category, :subcategory)

    render "search.json.jbuilder", locals: {
      tossups: limit ? tossups.limit(QUESTION_SEARCH_LIMT) : tossups,
      num_tossups_found: tossups.size,
      bonuses: limit ? bonuses.limit(QUESTION_SEARCH_LIMT) : bonuses,
      num_bonuses_found: bonuses.size
    }
  end

  # GET /tossups
  # GET /tossups.json
  def index
    @tossups = Tossup.all
  end

  # GET /tossups/1
  # GET /tossups/1.json
  def show
  end

  # POST /tossups
  # POST /tossups.json
  def create
    # @tossup = tossup.new(tossup_params)
    #
    # if @tossup.save
    #   render :show, status: :created, location: @tossup
    # else
    #   render json: @tossup.errors, status: :unprocessable_entity
    # end
  end

  # PATCH/PUT /tossups/1
  # PATCH/PUT /tossups/1.json
  def update
    # if @tossup.update(tossup_params)
    #   render :show, status: :ok, location: @tossup
    # else
    #   render json: @tossup.errors, status: :unprocessable_entity
    # end
  end

  # DELETE /tossups/1
  # DELETE /tossups/1.json
  def destroy
    # @tossup.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tossup
      @tossup = Tossup.find(params[:id])
    end

    def search_params
      params.require(:search).permit(:query, :limit, [
                                      filters: [
                                        difficulty: [], search_type: [],
                                        subcategory: [], question_type: [],
                                        tournament: [], category: []
                                      ]
                                    ])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tossup_params
      params.require(:tossup).permit(:text, :answer, :number, :tournament_id,
                                     :category_id, :subcategory_id, :round)
    end
end
