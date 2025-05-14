import java.time.LocalTime;

class FilterByTime extends Filter {
        private LocalTime[] time;
        public FilterByTime(LocalTime... times) {
            this.time = times;
        }
        public boolean accept(Song music) {
            for(int i=0;i<time.length;i++){
                if(time[i].equals(music.getTime())){
                    return true;
                }
            }
            return false;
        }
}
