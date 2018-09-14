require 'oystercard'

describe Oystercard do

  let(:entry_station) { double(:station) }
  let(:exit_station) { double(:station) }
  let(:min_balance) { Oystercard::MINIMUM_BALANCE }
  let(:max_balance) { Oystercard::MAXIMUM_BALANCE }
  let(:min_fare) { Journey::MINIMUM_FARE }
  let(:penalty_fare) { Journey::PENALTY_FARE }

  describe '#balance' do
    it 'returns an initial @balance of 0' do
      expect(subject.balance).to eq(0)
    end
  end

  describe '#top_up' do

    it 'updates the balance when passed a value' do
      value = rand(1..50)
      expect { subject.top_up(value) }.to change { subject.balance }.by(value)
    end

    it 'fails if @balance will go over MAXIMUM_BALANCE' do
      value = max_balance + 1
      expect { subject.top_up(value) }.to raise_error("Value exceeds maximum allowed: #{max_balance}")
    end

  end

  describe '#touch_in' do

    it 'fails when @balance is below MINIMUM_BALANCE' do
      expect { subject.touch_in(entry_station) }.to raise_error('Balance too low')
    end

    it 'sets the starting station' do
      subject.top_up(min_balance)
      subject.touch_in(entry_station)

      expect(subject.journey.entry_station).to eq(entry_station)
    end

    it 'charges a penalty fare if touched in twice' do
      subject.top_up(max_balance)
      subject.touch_in(entry_station)
      subject.touch_in(exit_station)

      expect(subject.balance).to eq(max_balance - penalty_fare)
    end

  end

  describe '#touch_out' do

    context 'card has touched in' do
      before { subject.top_up(max_balance) }
      before { subject.touch_in(entry_station) }

      it 'checks the journey has finished' do
        subject.touch_out(exit_station)

        expect(subject).to_not be_in_journey
      end

      it 'charges a normal fare after previous penalty fare ' do
        subject.touch_in(entry_station)
        subject.touch_out(exit_station)

        expect(subject.balance).to eq(max_balance - penalty_fare - min_fare)
      end

      it 'deducts journey fare from @balance' do
        subject.touch_in(entry_station)

        expect { subject.touch_out(exit_station) }.to change{ subject.balance }.by(- min_fare)
      end

      it 'adds entry_station and end_station to @journey_history' do
        subject.touch_in(entry_station)
        subject.touch_out(exit_station)

        expect(subject.journey_history).to eq(
          [{
            entry_station: entry_station,
            exit_station: exit_station
          }]
        )
      end

    end

    context 'card has not touched in' do

      it 'charges a penalty fare if touching out without touching in' do
        expect { subject.touch_out(exit_station) }.to change { subject.balance }.by(- penalty_fare)
      end

    end

  end

  describe '#in_journey?' do
    before { subject.top_up(max_balance) }

    it 'shows whether a card is in journey' do
      subject.touch_in(entry_station)

      expect(subject).to be_in_journey
    end

    it 'shows whether a card is in journey' do
      subject.touch_in(entry_station)
      subject.touch_out(exit_station)

      expect(subject).not_to be_in_journey
    end  

  end

end