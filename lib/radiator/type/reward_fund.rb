#!/opt/local/bin/ruby
############################################################# {{{1 ##########
#  Copyright © 2019 Martin Krischik «krischik@users.sourceforge.net»
#############################################################################
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see «http://www.gnu.org/licenses/».
############################################################# }}}1 ##########

##
# Class handling the date from the reward pool.
#
module Radiator
   module Type
      class Reward_Fund < Serializer
         ##
         # add the missing attribute reader.
         #
         attr_reader :base,
                     :quote,
                     :name,
                     :reward_balance,
                     :recent_claims,
                     :last_update,
                     :content_constant,
                     :percent_curation_rewards,
                     :percent_content_rewards,
                     :author_reward_curve,
                     :curation_reward_curve

         ##
         # create instance form Steem JSON object.
         #
         # @param [Hash]
         #    JSON object from condenser_api API.
         #
         def initialize(value, chain)
            super(:name, value)

            @name                     = value.name
            @reward_balance           = Amount.new(value.reward_balance, chain)
            @recent_claims            = value.recent_claims.to_i
            @last_update              = Time.strptime(value.last_update + ":Z", "%Y-%m-%dT%H:%M:%S:%Z")
            @content_constant         = value.content_constant
            @percent_curation_rewards = value.percent_curation_rewards
            @percent_content_rewards  = value.percent_content_rewards
            @author_reward_curve      = value.author_reward_curve
            @curation_reward_curve    = value.curation_reward_curve

            return
         end
      end # Reward_Fund
   end # Type
end # Radiator

############################################################ {{{1 ###########
# vim: set nowrap tabstop=8 shiftwidth=3 softtabstop=3 expandtab :
# vim: set textwidth=0 filetype=ruby foldmethod=syntax nospell :
# vim: set spell spelllang=en_gb fileencoding=utf-8 :
