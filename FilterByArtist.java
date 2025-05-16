class FilterByArtist extends Filter {
    private Artist[] artist;
    public FilterByArtist(Artist... artist) {
        this.artist = artist;
    }
    public boolean accept(Song music) {
        for(int i=0;i<artist.length;i++){
            if(artist[i].getName().contains(music.getArtist().getName())){
                return true;
            }
        }
        return false;
    }
}
/*باید فقط اسم یه خواننده رو بگیریم و فیلترش کنیم نه چندتا خواننده

    public FilterByArtist(String artist) {
        this.artist = artist;
    }

    @Override
    public boolean accept(Song song) {
        return artist.equalsIgnoreCase(song.getArtist());
    }
}*/
